library(shiny)
library(httr2)

authorize_url <- 'https://auth.ebsproject.org/oauth2/authorize'
access_url    <- 'https://auth.ebsproject.org/oauth2/token'
redirect_uri  <- 'http://localhost:1410'

# contact EBS server administrator to get these client id and secret 
client_id     <- 'xxxxxxxxxxxxxxxxxxxxxxxxx'
client_secret <- 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

EBS_client <- httr2::oauth_client(
  id        = client_id,
  secret    = client_secret,
  token_url = access_url,
  name      = "EBS"
)

# set_cookie <- function(session, name, value){
#   stopifnot(is.character(name) && length(name) == 1)
#   stopifnot(is.null(value) || (is.character(value) && length(value) == 1))
#   if(is.null(value)) { value <- "" }
#
#   cookie_options <- list(path = "/", same_site = "None", secure = TRUE)
#   parts <- rlang::list2(!!name := value, !!!cookie_options)
#   parts <- parts[!vapply(parts, is.null, logical(1))]
#
#   names  <- names(parts)
#   sep    <- ifelse(vapply(parts, isTRUE, logical(1)), "", "=")
#   values <- ifelse(vapply(parts, isTRUE, logical(1)), "", as.character(parts))
#   header <- paste(collapse = "; ", paste0(names, sep, values))
#   hdr    <- list("Set-Cookie" = header)
#
#   script_url <- session$registerDataObj(
#     name = paste("type", "cookie", httr2:::base64_url_rand(), sep = "_"),
#     data = httpResponse(headers = hdr),
#     filterFunc = function(data, req) {data}
#   )
#
#   insertUI("body", where = "afterBegin", immediate = TRUE, session = session,
#            ui = tagList(tags$script(src = script_url)))
# }


ui <- fluidPage(
  tags$style(type = "text/css", "#msg {white-space: pre-wrap;}"),

  tags$script('Shiny.addCustomMessageHandler("redirect",
              function(url) {window.location.href = (url)})'),

  tags$script('Shiny.addCustomMessageHandler("set_cookie",
              function(oauth_state) {document.cookie = "oauth2_state=" + oauth_state})'),

  tags$script('$(document).on("shiny:connected",
              function() {Shiny.setInputValue("cookies", document.cookie)});'),

  actionButton("login", "Sign In"),
  verbatimTextOutput("msg")
)

server <- function(input, output, session) {
  observeEvent(input$login, {
    oauth_state <- httr2:::base64_url_rand()

    # set_cookie(session, "oauth3_state", oauth_state)
    session$sendCustomMessage("set_cookie", oauth_state)

    auth_url <- httr2::oauth_flow_auth_code_url(
      client       = EBS_client,
      auth_url     = authorize_url,
      redirect_uri = redirect_uri,
      state        = oauth_state
    )

    session$sendCustomMessage("redirect", auth_url)
  })

  observeEvent(input$cookies, {
    oauth_state <- sub(".*oauth_state=([^;]*).*", "\\1", input$cookies)

    query <- parseQueryString(session$clientData$url_search)

    if (!is.null(query$code) && !is.null(query$state) && oauth_state != "") {
      code <- httr2:::oauth_flow_auth_code_parse(query, oauth_state)

      token <- httr2:::oauth_client_get_token(client = EBS_client,
                                              grant_type = "authorization_code",
                                              code = query$code,
                                              state = query$state,
                                              redirect_uri = redirect_uri)

      output$msg <- renderText(token$access_token)

      QBMS::set_qbms_config(url = 'https://cbbrapi-wee.ebsproject.org', engine = 'ebs', brapi_ver = 'v2')
      QBMS::set_token(token$id_token, '', token$expires_at)

      output$msg <- renderText(QBMS::list_programs()$programName)
    }
  })

}

shinyApp(ui, server, options = list(port = 1410, launch.browser = TRUE))
