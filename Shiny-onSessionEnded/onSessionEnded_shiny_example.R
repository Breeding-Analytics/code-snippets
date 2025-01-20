library("shiny")

ui <- fluidPage(
  "Nothing here!"
)

server <- function(input, output, session) {
  # this code will be run once per user
  users_data <- data.frame(START = Sys.time())
  
  # this code will be run after the client has disconnected
  session$onSessionEnded(function() {
    users_data$END <- Sys.time()
    
    # write (append) to a file in your working directory
    write.table(x = users_data, file = file.path(getwd(), "users_data.txt"),
                append = TRUE, row.names = FALSE, col.names = FALSE, sep = "\t")
  })
}

shinyApp(ui = ui, server = server, options = list(port = 1410, launch.browser = TRUE))