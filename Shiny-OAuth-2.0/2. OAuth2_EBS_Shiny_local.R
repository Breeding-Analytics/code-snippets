library(shiny)
library(httr2)

EBS_client <- httr2::oauth_client(
  # contact EBS server administrator to get these client id and secret 
  id        = "xxxxxxxxxxxxxxxxxxxxxxxxx",
  secret    = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  token_url = "https://auth.ebsproject.org/oauth2/token",
  name      = "EBS"
)

ui <- fluidPage(
  tags$style(type = "text/css", "#msg {white-space: pre-wrap;}"),

  actionButton("login", "Sign In"),
  verbatimTextOutput("msg")
)

server <- function(input, output, session) {
  observeEvent(input$login, {
    token <- httr2::oauth_flow_auth_code(
      client       = EBS_client,
      auth_url     = "https://auth.ebsproject.org/oauth2/authorize",
      redirect_uri = "http://localhost:1410"
    )
    
    output$msg <- renderText(token$access_token)
  })
}

shinyApp(ui, server, options = list(launch.browser = TRUE))
