library(shiny)
library(shinybusy)

library(future)
library(promises)
future::plan(future::multisession)

ui <- fluidPage(
  p("The time is ", textOutput("current_time")),
  hr(),
  numericInput("x", "x", value = 1),
  numericInput("y", "y", value = 2),
  actionButton("btn", "Add numbers"),
  textOutput("sum"),
  textOutput("obj")
)

server <- function(input, output, session) {
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })

  data <- reactiveVal(list(total = 0))

  sum_values <- ExtendedTask$new(function(input, data) {
    future_promise({
      # some long process
      Sys.sleep(5)

      z <- input$x + input$y
      data$total <- data$total + z

      return(list(output = z, obj = data))
    })
  })

  observeEvent(input$btn, {
    shinybusy::show_modal_spinner()

    ui_inputs <- shiny::reactiveValuesToList(input)
    data_obj  <- data()

    sum_values$invoke(ui_inputs, data_obj)
  })

  output$sum <- renderText({
    results <- sum_values$result()

    data(results$obj)

    shinybusy::remove_modal_spinner()

    return(results$output)
  })

  output$obj <- renderText({
    data()$total
  })
}

shinyApp(ui, server)

