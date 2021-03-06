#' UI of editData Shiny module
#' @param id A string
#' @importFrom shiny NS icon fluidPage fluidRow actionButton p conditionalPanel numericInput textInput
#' @importFrom DT dataTableOutput
#' @export
#' @examples
#'library(shiny)
#'# Only run examples in interactive R sessions
#'if (interactive()) {
#'ui <- fluidPage(
#'     textInput("mydata","Enter data name",value="mtcars"),
#'     editableDTUI("table1"),
#'     verbatimTextOutput("test"),
#'     editableDTUI("table2"),
#'     verbatimTextOutput("test2")
#')
#'server <- function(input, output) {
#'     df=callModule(editableDT,"table1",dataname=reactive(input$mydata),inputwidth=reactive(170))
#'
#'     output$test=renderPrint({
#'          str(df())
#'     })
#'     mydf<-editData::sampleData
#'     df2=callModule(editableDT,"table2",data=reactive(mydf))
#'     output$test2=renderPrint({
#'          str(df2())
#'     })
#'}
#'shinyApp(ui, server)
#'}
editableDTUI <- function(id){

    ns=NS(id)
    fluidPage(
    fluidRow(
        uiOutput(ns("buttons")),

        # radioButtons3(ns("selection"),"Data Selection",choices=c("single","multiple"),
        #               inline=TRUE,labelwidth=130,align="center"),
        # radioButtons3(ns("resultAs"),"Resultant Data as",choices=c("tibble","data.frame"),inline=TRUE,labelwidth=150,align="center"),
        p(""),
        DT::DTOutput(ns("origTable")),
        conditionalPanel(condition="true==false",
                         numericInput(ns("width2"),"width2",value=100),
                         textInput(ns("result"),"result",value=""),
                         numericInput(ns("no"),"no",value=1),
                         numericInput(ns("page"),"page",value=1),
                         checkboxInput(ns("resetPage"),"resetPage",value=FALSE)
                         )


    )
    )
}

#' Server function of editData Shiny module
#'
#' @param input input
#' @param output output
#' @param session session
#' @param dataname A string of representing data name
#' @param data A data object
#' @param inputwidth Numeric indicating default input width in pixel
#' @param mode An integer
#' @importFrom shiny updateTextInput updateNumericInput reactive validate need showModal modalDialog updateDateInput updateCheckboxInput updateSelectInput observe modalButton renderUI textAreaInput updateTextAreaInput removeModal
#' @importFrom DT renderDataTable datatable dataTableProxy replaceData selectPage
#' @importFrom dplyr select
#' @importFrom magrittr "%>%"
#' @export
editableDT <- function(input, output, session, dataname=reactive(""),data=reactive(NULL),inputwidth=reactive(100),mode=reactive(2)) {

    deleted<-deleted1<-edited<-edited1<-added<-added1<-updated1<-updated<-restored<-restored1<-c()

    defaultlen=20

    observe({

            updateTextInput(session,"result",value=dataname())

    })

    observe({
        updateNumericInput(session,"width2",value=inputwidth())
    })


    df=reactive({
          if(is.null(input$result)){
              df<-data()
          } else if(input$result!="") {
              df<-eval(parse(text=input$result))
          }
          else df<-data()

          df
    })

    output$buttons <-renderUI({
        ns <- session$ns
        amode=mode()
        tagList(
        actionButton(ns("delRow"),"Delete Row",icon=icon("remove",lib="glyphicon")),
        actionButton(ns("addRow"),"Add New",icon=icon("plus",lib="glyphicon")),
        actionButton(ns("insertRow"),"Insert Row",icon=icon("hand-up",lib="glyphicon")),
        actionButton(ns("editData"),"Edit Data",icon=icon("wrench",lib="glyphicon")),
        if(amode==1) actionButton(ns("newCol"),"New Col",icon=icon("plus-sign",lib="glyphicon")),
        if(amode==1) actionButton(ns("removeCol"),"Remove Col",icon=icon("trash",lib="glyphicon")),
        if(amode==1) actionButton(ns("dplyr"),"Manipulate",icon=icon("scissors",lib="glyphicon")),
        if(amode==2) actionButton(ns("reset"),"Reset",icon=icon("remove-sign",lib="glyphicon")),
        if(amode==2) actionButton(ns("restore"),"Restore",icon=icon("heart",lib="glyphicon"))
        )
    })

    output$origTable <- DT::renderDT({
        if(dataname()!=""){
        validate(
            need(any(class(try(eval(parse(text=input$result)))) %in% c("tbl_df","tibble","data.frame")),
                 "Please enter the valid data name")
        )
        }
        updateCheckboxInput(session,"resetPage",value=TRUE)
        datatable(
            df(),
            selection = "single",
            editable=TRUE,
            caption = NULL
        )


    })

    proxy = dataTableProxy('origTable')

    observeEvent(input$resetPage,{
        if(input$resetPage){
        proxy %>% selectPage(input$page)
        updateCheckboxInput(session,"resetPage",value=FALSE)
        }
    })


    observeEvent(input$origTable_cell_edit, {

        info = input$origTable_cell_edit
        # str(info)

        i = info$row
        j = info$col
        v = info$value
        x <- df()
        x[i, j] <- DT::coerceValue(v, x[i, j])
        replaceData(proxy, x, resetPaging = FALSE)  # important

        if(input$result=="updated"){
            updated1<<-x
            updateTextInput(session,"result",value="updated1")
        } else{
            updated<<-x
            updateTextInput(session,"result",value="updated")
        }
        updateNumericInput(session,"page",value=(i-1)%/%10+1)


    })

    observeEvent(input$delRow,{
        ids <- input$origTable_rows_selected
        if(length(ids)>0){
            x<-as.data.frame(df())
            restored<<-x
            x <- x[-ids,]

            if(input$result=="deleted"){
                deleted1<<-x
                updateTextInput(session,"result",value="deleted1")
            } else{
                deleted<<-x
                updateTextInput(session,"result",value="deleted")
            }
            updateNumericInput(session,"page",value=(ids[1]-1)%/%10+1)


        } else {
            showModal(modalDialog(
                title = "Delete Row",
                "Please Select Row(s) To Delete. Press 'Esc' or Press 'OK' button",
                easyClose = TRUE,
                footer=modalButton("OK")
            ))
        }
    })

    observeEvent(input$reset,{


            x<-as.data.frame(df())
            restored<<-x
            x <- x[-c(1:nrow(x)),]

            if(input$result=="deleted"){
                deleted1<<-x
                updateTextInput(session,"result",value="deleted1")
            } else{
                deleted<<-x
                updateTextInput(session,"result",value="deleted")
            }
   })

    observeEvent(input$restore,{


        if(length(restored) >0){
            updateTextInput(session,"result",value="restored")
        }  else {
            showModal(modalDialog(
                title = "Retore",
                "You can restore data after reset or delete row. Press 'Esc' or Press 'OK' button",
                easyClose = TRUE,
                footer=modalButton("OK")
            ))
        }
    })


    observeEvent(input$removeCol,{

         ns <- session$ns
         x<-as.data.frame(df())
         showModal(modalDialog(
              title = "Delete Column",
              "Please Select Row(s) To Delete. Press 'Esc' or Press 'OK' button",
              selectInput(ns("colRemove"),"Column to Remove",choices=colnames(x)),
              easyClose = TRUE,
              footer=tagList(
                   modalButton("Cancel"),
                   actionButton(ns("delCol"),"Remove")
              )
         ))

    })

    observeEvent(input$delCol,{

         x<-as.data.frame(df())

         x<- eval(parse(text=paste0("select(x,-",input$colRemove,")")))

        if(input$result=="deleted"){
            deleted1<<-x
            updateTextInput(session,"result",value="deleted1")
        } else{
            deleted<<-x
            updateTextInput(session,"result",value="deleted")
        }
        removeModal()

    })

    observeEvent(input$newCol,{

         ns <- session$ns
         x<-as.data.frame(df())
         showModal(modalDialog(
              title = "Calculate New Column",
              "You can add new column. Press 'Esc' or Press 'Mutate' button",
              textInput(ns("newColText"),"Calculate Column",value="",placeholder="LDL = TC - HDL - TG/5"),
              easyClose = TRUE,
              footer=tagList(
                   modalButton("Cancel"),
                   actionButton(ns("mutateCol"),"Mutate")
              )
         ))

    })

    observeEvent(input$mutateCol,{

         x<-as.data.frame(df())

         x1<- tryCatch(eval(parse(text=paste0("mutate(x,",input$newColText,")"))),error=function(e) "error")

         if(any(class(x) %in% c("data.frame","tibble","tbl_df"))) {

             rownames(x1)<- rownames(x)

             if(input$result=="added"){
              added1<<-x1
              updateTextInput(session,"result",value="added1")
         } else{
              added<<-x1
              updateTextInput(session,"result",value="added")
         }
         }

         removeModal()

    })

    observeEvent(input$dplyr,{

         ns <- session$ns
         x<-as.data.frame(df())
         showModal(modalDialog(
              title = "Data manipulation",
              "You can manipulate data with dplyr code. Press 'Esc' or Press 'Manipulate' button",
              textAreaInput(ns("newCode"),"data <- data %>%",value="",rows=5,
                        placeholder="filter(cyl==6)"),
              easyClose = TRUE,
              footer=tagList(
                   modalButton("Cancel"),
                   actionButton(ns("manipulate"),"Manipulate")
              )
         ))

    })

    observeEvent(input$manipulate,{

         x<-as.data.frame(df())

         mycode=paste0("x %>%",input$newCode)

         x1<- tryCatch(eval(parse(text=mycode)),error=function(e) "error")

         if(any(class(x) %in% c("data.frame","tibble","tbl_df"))) {

             if(nrow(x1)==nrow(x)) rownames(x1)<- rownames(x)

              if(input$result=="edited"){
                   edited1<<-x1
                   updateTextInput(session,"result",value="edited1")
              } else{
                   edited<<-x1
                   updateTextInput(session,"result",value="edited")
              }
         }
         removeModal()

    })


    observeEvent(input$remove,{


         x<-as.data.frame(df())
         x <- x[-input$no,]

         if(input$result=="deleted"){
              deleted1<<-x
              updateTextInput(session,"result",value="deleted1")
         } else{
              deleted<<-x
              updateTextInput(session,"result",value="deleted")
         }
         if(input$no>nrow(x)) updateNumericInput(session,"no",value=nrow(x))

    })

    observeEvent(input$addRow,{

        x<-as.data.frame(df())
        x1 <- tibble::add_row(x)
        newname=max(as.numeric(rownames(x)),nrow(x),na.rm=TRUE)+1

        rownames(x1)=c(rownames(x),newname)

        if(input$result=="added"){
            added1<<-x1
            updateTextInput(session,"result",value="added1")
        } else{
            added<<-x1
            updateTextInput(session,"result",value="added")
        }
        updateNumericInput(session,"no",value=nrow(x1))
        editData2()
        updateNumericInput(session,"page",value=(nrow(x)-1)%/%10+1)

    })

    observeEvent(input$insertRow,{
         ids <- input$origTable_rows_selected
         if(length(ids)>0){
              ids<-ids[1]
              if(ids>1){
              x<-as.data.frame(df())
              x1 <- x[1:(ids-1),]

              x1 <- tibble::add_row(x1)
              x1 <-rbind(x1,x[ids:nrow(x),])

              newname=max(as.numeric(rownames(x)),nrow(x),na.rm=TRUE)+1
              rownames(x1)=c(rownames(x)[1:(ids-1)],newname,rownames(x)[ids:nrow(x)])
              } else{
                   x<-as.data.frame(df())
                   x1<-x
                   x1 <- tibble::add_row(x1)
                   x1=x1[c(nrow(x1),1:(nrow(x1)-1)),]

                   newname=max(as.numeric(rownames(x)),nrow(x),na.rm=TRUE)+1
                   rownames(x1)=c(newname,rownames(x))
              }
               if(input$result=="added"){
                    added1<<-x1
                    updateTextInput(session,"result",value="added1")
               } else{
                    added<<-x1
                    updateTextInput(session,"result",value="added")
               }
              updateNumericInput(session,"no",value=ids)
              editData2()
              updateNumericInput(session,"page",value=(ids-1)%/%10+1)

         } else{
              showModal(modalDialog(
                   title = "Insert New Data",
                   "Please Select Row To Insert. Press 'Esc' or Press 'OK' button",
                   easyClose = TRUE,
                   footer=modalButton("OK")
              ))
         }


    })

    observeEvent(input$new,{

        x<-as.data.frame(df())
        x1 <- tibble::add_row(x)

        newname=max(as.numeric(rownames(x)),nrow(x),na.rm=TRUE)+1
        rownames(x1)=c(rownames(x),newname)

        if(input$result=="added"){
            added1<<-x1
            updateTextInput(session,"result",value="added1")
        } else{
            added<<-x1
            updateTextInput(session,"result",value="added")
        }
        updateNumericInput(session,"no",value=newname)

    })

    observeEvent(input$update,{
        ids <- input$no
        x<-df()
        restored<<-x

        myname=colnames(x)
        status=ifelse(tibble::has_rownames(x),1,0)
        x<-as.data.frame(x)
        rownames(x)[ids]=input$rowname

        # for(i in 1:ncol(x)){
        #     x[ids,i]=input[[myname[i]]]
        # }

        for(i in 1:ncol(x)){
             #x[ids,i]=input[[myname[i]]]
             try(x[ids,i]<-input[[myname[i]]])
             if("POSIXct" %in% class(x[ids,i])){
                   tz=""
                   if(!is.null(attr(x[ids,i],"tzone"))) tz=attr(x[ids,i],"tzone")
                   x[ids,i]=as.POSIXct(input[[myname[i]]],tz=tz,origin="1970-01-01")
             }
        }
        if(input$result=="updated"){
            updated1<<-x
            updateTextInput(session,"result",value="updated1")
        } else{
            updated<<-x
            updateTextInput(session,"result",value="updated")
        }
        #updateCheckboxInput(session,"showEdit",value=FALSE)
    })

    observeEvent(input$Close,{
        updateCheckboxInput(session,"showEdit",value=FALSE)
    })

    observeEvent(input$no,{
        mydf2=df()

        if(!is.null(mydf2)){
        myclass=lapply(mydf2,class)

        updateTextInput(session,"rowname",value=rownames(mydf2)[input$no])
        updateNumericInput(session,"width",value=input$width)
        mydf=as.data.frame(mydf2[input$no,])
        for(i in 1:ncol(mydf)){
            myname=colnames(mydf)[i]
            if("factor" %in% myclass[[i]]){
                updateSelectInput(session,myname,
                                  choices=levels(mydf[[i]]),selected=mydf[1,i])
            } else if("Date" %in% myclass[[i]]){
                updateDateInput(session,myname,value=mydf[1,i])
            } else if("logical" %in% myclass[[i]]){
                if(is.na(mydf[1,i])) myvalue=FALSE
                else myvalue=mydf[1,i]
                updateCheckboxInput(session,myname,value=myvalue)
            } else { # c("numeric","integer","charater")

                 mywidth=(((max(nchar(mydf2[[i]]),defaultlen,na.rm=TRUE)*8) %/% input$width2)+1)*input$width2
                 if(mywidth<=500){
                    updateTextInput(session,myname,value=mydf[1,i])
                 } else{
                      updateTextAreaInput(session,myname,value=mydf[1,i])
                 }
            }
        }
        }

    })

    observeEvent(input$home,{
        updateNumericInput(session,"no",value=1)
    })

    observeEvent(input$end,{
        updateNumericInput(session,"no",value=nrow(df()))
    })

    observeEvent(input$left,{
        value=ifelse(input$no>1,input$no-1,1)
        updateNumericInput(session,"no",value=value)
    })

    observeEvent(input$right,{

        value=ifelse(input$no<nrow(df()),input$no+1,nrow(df()))
        updateNumericInput(session,"no",value=value)
    })

    observeEvent(input$rowno,{
        maxno=nrow(df())
        print(maxno)
        print(input$rowno)
        if(is.na(input$rowno)) updateNumericInput(session,"rowno",value=maxno)
        if(input$rowno>maxno) {
            updateNumericInput(session,"rowno",value=maxno)
            updateNumericInput(session,"no",value=maxno)
        } else{
            updateNumericInput(session,"no",value=input$rowno)
        }

    })

    output$test2=renderUI({
        ns <- session$ns
        ids <- input$no
        if(length(ids)==1){

            mydf2=df()
            mylist=list()
            myclass=lapply(mydf2,class)
            mylist[[1]]=actionButton(ns("home"),"",icon=icon("backward",lib="glyphicon"))
            mylist[[2]]=actionButton(ns("left"),"",icon=icon("chevron-left",lib="glyphicon"))
            mylist[[3]]=numericInput3(ns("rowno"),"rowno",value=input$no,min=1,
                                      max=nrow(mydf2),step=1,width=50+10*log10(nrow(mydf2)))
            mylist[[4]]=actionButton(ns("right"),"",icon=icon("chevron-right",lib="glyphicon"))
            mylist[[5]]=actionButton(ns("end"),"",icon=icon("forward",lib="glyphicon"))
            mylist[[6]]=actionButton(ns("new"),"",icon=icon("plus",lib="glyphicon"))
            mylist[[7]]=textInput3(ns("rowname"),"rowname",value=rownames(mydf2)[input$no],width=150)
            mylist[[8]]=numericInput3(ns("width"),"input width",value=input$width2,min=100,max=500,step=50,width=80)
            mylist[[9]]=hr()
            addno=9
            mydf=as.data.frame(mydf2[input$no,])
            for(i in 1:ncol(mydf)){
                myname=colnames(mydf)[i]
                if("factor" %in% myclass[[i]]){
                    mylist[[i+addno]]=selectInput3(ns(myname),myname,
                                                   choices=levels(mydf[[i]]),selected=mydf[1,i],width=input$width2)
                } else if("Date" %in% myclass[[i]]){
                    mylist[[i+addno]]=dateInput3(ns(myname),myname,value=mydf[1,i],width=input$width2)
                } else if("logical" %in% myclass[[i]]){
                    if(is.na(mydf[1,i])) myvalue=FALSE
                    else myvalue=mydf[1,i]
                    mylist[[i+addno]]=checkboxInput3(ns(myname),myname,value=myvalue,width=input$width2)
                } else { # c("numeric","integer","charater")
                     #cat("max(nchar(mydf2[[i]]))=",max(nchar(mydf2[[i]])))
                     #cat("\n",mydf2[[i]][which.max(nchar(mydf2[[i]]))],"\n")
                     mywidth=(((max(nchar(mydf2[[i]]),defaultlen,na.rm=TRUE)*8) %/% input$width2)+1)*input$width2
                     #cat("mywidth=",mywidth,"\n")
                     if(mywidth<=500){
                     mylist[[i+addno]]=textInput3(ns(myname),myname,value=mydf[1,i],width=mywidth)
                     } else{
                          mylist[[i+addno]]=textAreaInput(ns(myname),myname,value=mydf[1,i],width="500px")
                     }
                }
            }
            do.call(tagList,mylist)
        } else{

            h4("You can edit data after select one row in datatable.")

        }


    })

    observeEvent(input$width,{
        updateNumericInput(session,"width2",value=input$width)
    })
    observeEvent(input$editData,{
        ids <- input$origTable_rows_selected
        if(length(ids)==1) updateNumericInput(session,"no",value=ids)
        else if(input$no>nrow(df())) updateNumericInput(session,"no",value=1)
        #updateCheckboxInput(session,"showEdit",value=TRUE)
        editData2()
        updateNumericInput(session,"page",value=(ids-1)%/%10+1)
    })

    editData2=reactive({

        input$editData
        input$addRow

        ns <- session$ns

        showModal(modalDialog(
            title="Edit Data",
            footer=tagList(
                actionButton(ns("remove"),"Delete",icon=icon("remove",lib="glyphicon")),
                actionButton(ns("update"),"Update",icon=icon("ok",lib="glyphicon")),
                modalButton("Close",icon=icon("eject",lib="glyphicon"))),
            easyClose=TRUE,
            uiOutput(ns("test2"))
        ))
    })


    return(df)

}


#' A shiny app for editing a 'data.frame'
#' @param data A tibble or a tbl_df or a data.frame to manipulate
#' @param viewer Specify where the gadget should be displayed. Possible choices are c("dialog","browser","pane")
#' @param mode An integer
#' @importFrom rstudioapi getActiveDocumentContext
#' @importFrom miniUI miniPage gadgetTitleBar miniContentPanel
#' @importFrom utils read.csv str write.csv
#' @importFrom shiny stopApp callModule runGadget column fileInput downloadButton renderPrint observeEvent tagList uiOutput browserViewer dialogViewer downloadHandler h4 hr paneViewer checkboxInput
#' @return A manipulated 'data.frame' or NULL
#' @export
#' @examples
#' library(shiny)
#' library(editData)
#'# Only run examples in interactive R sessions
#' if (interactive()) {
#'     result<-editData(mtcars)
#'     result
#' }
editData=function(data=NULL,viewer="dialog",mode=2){

    sampleData<-editData::sampleData
    context <- rstudioapi::getActiveDocumentContext()

    # Set the default data to use based on the selection.
    text <- context$selection[[1]]$text
    defaultData <- text

    if(is.null(data)) {
        if(nzchar(defaultData)) {
            mydata=defaultData
        } else {
            mydata="sampleData"
        }
    }

    if(any(class(data) %in% c("data.frame","tibble","tbl_df"))) {
        mydata=deparse(substitute(data))
    } else if(class(data) =="character") {

        result<-tryCatch(eval(parse(text=data)),error=function(e) "error")
        if(any(class(result) %in% c("data.frame","tibble","tbl_df"))) mydata=data
        else  return(NULL)
    }


ui<-miniPage(
    gadgetTitleBar("editable DataTable"),
    miniContentPanel(
    fluidRow(

        column(6,
    fileInput("file1","Upload CSV file"),
    checkboxInput("strAsFactor","strings As Factor",value=FALSE)),
    column(6,
    textInput3("mydata","Or Enter data name",value=mydata,width=150,bg="lightcyan"))),
    editableDTUI("table1"),
    downloadButton("downloadData","Download as CSV")
    #,verbatimTextOutput("test")

    # ,editableDTUI("table2"),
    # verbatimTextOutput("test2")
))

server=function(input,output,session){

     if(!isNamespaceLoaded("tidyverse")){
          attachNamespace("tidyverse")
     }

    uploaded <-c()

    mydf=reactive({
        validate(
            need(any(class(try(eval(parse(text=input$mydata)))) %in% c("tbl_df","tibble","data.frame")),"Enter Valid Data Name"))
        mydf=eval(parse(text=input$mydata))
        mydf
    })
    df=callModule(editableDT,"table1",data=reactive(mydf()),inputwidth=reactive(170),mode=reactive(mode))

    # output$test=renderPrint({
    #     str(df())
    # })

    observeEvent(input$file1,{
        if(!is.null(input$file1)) {
            uploaded<<-read.csv(input$file1$datapath,stringsAsFactors = input$strAsFactor)
            updateTextInput(session,"mydata",value="uploaded")
        }
    })


    # mydf<-editData::sampleData
    #
    # df2=callModule(editableDT,"table2",data=reactive(mydf))
    #
    # output$test2=renderPrint({
    #     str(df2())
    # })
    output$downloadData <- downloadHandler(
        filename = function() {
            paste("edited-",Sys.Date(),".csv", sep = "")
        },
        content = function(file) {
            write.csv(df(), file, row.names = FALSE)
        }
    )

    observeEvent(input$done, {

        # if(nzchar(defaultData)) {
        #     insertText(text=input$code)
        #     stopApp()
        # } else{
        #     result <- eval(parse(text=input$code))
        #     attr(result,"code") <- input$code
        #     stopApp(result)
        # }
        result=df()
        # if(input$resultAs=="tibble"){
        #     result<-as_tibble(result)
        # } else{
        #     result<-as.data.frame(result)
        # }
        stopApp(result)
    })

    observeEvent(input$cancel, {

        stopApp()
    })
}

if(viewer=="dialog") myviewer <- dialogViewer("editData", width = 1000, height = 800)
else if(viewer=="browser") myviewer <- browserViewer()
else myviewer <- paneViewer()
runGadget(ui, server, viewer = myviewer)
}


