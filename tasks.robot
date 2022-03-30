*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create news Directory
    Open the robot order website
    [Teardown]    Close the browser

*** Variables ***

${FILECSV}=     orders.csv
${FOLDERFILES}=        ${CURDIR}${/}output
${URLDOWNLOAD}=    https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Create news Directory    
    Create Directory    ${CURDIR}${/}output${/}results    
    Create Directory    ${CURDIR}${/}output${/}results${/}receipt
    Create Directory    ${CURDIR}${/}output${/}results${/}imagesrobot 

Open the robot order website
    # Get the Vault
    ${secret}=    Get Secret    credentials
    ${secretUrl}    Set Variable    ${secret}[url]
   
    # Open browser
    Open Available Browser    ${secretUrl}        maximized=true
    # Download the file csv
    Download    ${URLDOWNLOAD}    overwrite=true

    @{orders}=    Read Table From Csv    ${FILECSV}    header=True
    
    
    FOR    ${row}    IN    @{orders}
            
            Close the annoyng modal
            
            Fill the form    ${row}

            Preveiw the robot

            Submit the order
                        
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]

            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
           
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    

            Go to order another robot

    END
    Create a ZIP file of the receipts  


Close the annoyng modal
    # Close the popup
    Click Button    OK
Fill the form
    # Fill the form
    [Arguments]    ${row}
   
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input        ${row}[Legs]
    Input Text    address    ${row}[Address]

Preveiw the robot
    #Click button preview
    Click Button    preview

Submit the order   
    #Click button order 
    Click Button    order        
    # Validate if click button order is ok        
    ${exist}=    Is Element Visible    order    2s    
    Log To Console     variable result: ${exist}
    
    IF  ${exist}
        ${i}=    Set Variable    1
        ${simExiste}=    Set Variable    'sim'    
     #while loop doesn't work in this version so I used the for loop   
        FOR    ${i}    IN RANGE    8
                       
            Click Button    preview
            Click Button    order
            ${exist}=    Is Element Visible    order
            Log    ${exist}
            IF    ${exist}
                ${simExiste}=    Set Variable    'sim'
            ELSE
                ${simExiste}=    Set Variable    'nao'
                Exit For Loop If    ${simExiste} == 'nao'
            END    
            ${i}=    Evaluate    ${i} + 1
        END
            
    END

Go to order another robot
    #Click button another robot
    Click Button    order-another

Store the receipt as a PDF file
    # Save the receipt as a pdf in the folder results/receipt
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt  
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${FOLDERFILES}${/}results${/}receipt${/}${row}.pdf
    ${pdf}    Set Variable    ${FOLDERFILES}${/}results${/}receipt${/}${row}.pdf
    [Return]    ${pdf}    
    
Take a screenshot of the robot
    # Save the screenshot as a png in the folder results/imagesrobot
    [Arguments]    ${row}

    Screenshot    robot-preview-image    ${FOLDERFILES}${/}results${/}imagesrobot${/}${row}.png
    ${screenshot}    Set Variable    ${FOLDERFILES}${/}results${/}imagesrobot${/}${row}.png
    [Return]    ${screenshot}

Create a ZIP file of the receipts
    # Create a zip file the receipts
    # Using assistant
    Add heading  *** Execution completed successfully ***
    Add icon    Success
    Add text input    message
    ...    label=What's your name?
    ...    placeholder=Enter your name here to include in the zip file
    ...    rows=1   
    ${result}=    Run dialog
    Log To Console    Typed name:${result.message}
    
    Archive Folder With Zip    ${FOLDERFILES}${/}results${/}receipt    ${FOLDERFILES}${/}receipts_images_${result.message}.zip


Embed the robot screenshot to the receipt PDF file
# Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    
    
        
    @{listpng}    Create List    ${screenshot}:align=center

    Open Pdf    ${pdf}    

    Add Files To Pdf    ${listpng}     ${pdf}       ${true}        

    Close Pdf                                      
Close the browser
# Close the browser
    Close Browser
