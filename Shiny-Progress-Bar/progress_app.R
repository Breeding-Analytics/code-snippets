library(shiny)
library(shinybusy)

ui <- fluidPage(
  plotOutput("plot", width = "300px", height = "300px"),
  actionButton("run", "Start?")
)

server <- function(input, output) {

  result <- eventReactive(input$run, {

    shinybusy::show_modal_spinner()

    x <- numeric(0)
    n <- 10

    # https://shiny.posit.co/r/articles/build/progress/
    withProgress(message = "Long Process", value = 0, {

      for (i in 1:n) {
        Sys.sleep(1)

        x <- c(x, rnorm(10, 0, 1))

        incProgress(1/n, detail = paste("Doing part", i))
      }

    })

    shinybusy::remove_modal_spinner()

    return(x)
  })

  output$plot <- renderPlot({
    x <- result()

    hist(x)
  })
}

shinyApp(ui, server)
