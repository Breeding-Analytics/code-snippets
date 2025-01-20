library(shiny)
library(reactlog)
library(shinybusy)

# tell shiny to log all reactivity
reactlog_enable()

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

  sum_values <- eventReactive(input$btn, {
    shinybusy::show_modal_spinner()

    # some long process
    Sys.sleep(5)
    z <- input$x + input$y

    temp <- data()
    temp$total <- temp$total + z
    data(temp)

    shinybusy::remove_modal_spinner()

    return(z)
  })

  output$sum <- renderText({
    results <- sum_values()
    return(results)
  })

  output$obj <- renderText({
    data()$total
  })
}

shinyApp(ui, server)

# once app has closed, display reactlog from shiny
shiny::reactlogShow()
