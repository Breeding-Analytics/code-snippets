library(shiny)
library(httr2)

authorize_url <- "https://serviceportal-authentication-tst.azurewebsites.net/connect/authorize"
access_url    <- "https://serviceportal-authentication-tst.azurewebsites.net/connect/token"
redirect_uri  <- 'http://localhost:1410'

# contact Scriptoria server administrator to get these client id and secret 
client_id     <- 'xxxxxxxxxxxxxxxxxxxxxxxxx'
client_secret <- 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

Scriptoria_client <- httr2::oauth_client(
  id        = client_id,
  secret    = client_secret,
  token_url = access_url,
  name      = "Scriptoria"
)

set_cookie <- function(session, name, value){
  stopifnot(is.character(name) && length(name) == 1)
  stopifnot(is.null(value) || (is.character(value) && length(value) == 1))
  if(is.null(value)) { value <- "" }

  cookie_options <- list(path = "/", same_site = "None", secure = TRUE)
  parts <- rlang::list2(!!name := value, !!!cookie_options)
  parts <- parts[!vapply(parts, is.null, logical(1))]

  names  <- names(parts)
  sep    <- ifelse(vapply(parts, isTRUE, logical(1)), "", "=")
  values <- ifelse(vapply(parts, isTRUE, logical(1)), "", as.character(parts))
  header <- paste(collapse = "; ", paste0(names, sep, values))
  hdr    <- list("Set-Cookie" = header)

  script_url <- session$registerDataObj(
    name = paste("type", "cookie", httr2:::base64_url_rand(), sep = "_"),
    data = httpResponse(headers = hdr),
    filterFunc = function(data, req) {data}
  )

  insertUI("body", where = "afterBegin", immediate = TRUE, session = session,
           ui = tagList(tags$script(src = script_url)))
}


ui <- fluidPage(
  tags$script('Shiny.addCustomMessageHandler("redirect",
              function(url) {window.location.href = (url)})'),

  tags$script('$(document).on("shiny:connected",
              function() {Shiny.setInputValue("cookies", document.cookie)});'),

  actionButton("login", "Sign In"),
  verbatimTextOutput("msg")
)

server <- function(input, output, session) {
  observeEvent(input$login, {
    pkce <- httr2::oauth_flow_auth_code_pkce()

    set_cookie(session, "pkce_verifier", pkce$verifier)

    oauth_state <- httr2:::base64_url_rand()

    set_cookie(session, "oauth_state", oauth_state)

    auth_url <- httr2::oauth_flow_auth_code_url(
      client       = Scriptoria_client,
      auth_url     = authorize_url,
      redirect_uri = redirect_uri,
      state        = oauth_state,
      auth_params  = list(
        scope                 = "openid profile",
        code_challenge        = pkce$challenge,
        code_challenge_method = pkce$method
      )
    )

    session$sendCustomMessage("redirect", auth_url)
  })

  observeEvent(input$cookies, {
    pkce_verifier <- sub(".*pkce_verifier=([^;]*).*", "\\1", input$cookies)
    oauth_state   <- sub(".*oauth_state=([^;]*).*", "\\1", input$cookies)

    query <- parseQueryString(session$clientData$url_search)

    if (!is.null(query$code) && !is.null(query$state)) {
      code <- httr2:::oauth_flow_auth_code_parse(query, oauth_state)

      token <- httr2:::oauth_client_get_token(client     = Scriptoria_client,
                                              grant_type = "authorization_code",
                                              code  = query$code,
                                              state = query$state,
                                              code_verifier = pkce_verifier,
                                              redirect_uri  = redirect_uri)

      jwt     <- strsplit(token$access_token, ".", fixed = TRUE)[[1]]
      payload <- jsonlite::base64url_dec(jwt[2]) |>
                 rawToChar() |>
                 jsonlite::fromJSON()

      output$msg <- renderText(payload$email)
    }
  })

}

shinyApp(ui, server, options = list(port = 1410, launch.browser = TRUE))
