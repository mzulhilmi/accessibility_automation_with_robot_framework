*** Settings ***
Documentation           This is a simple accessibility test with Robot Framework
Library                 Selenium2Library
Library                 OperatingSystem
Library                 String
Library                 DateTime
Library                 Collections
Library                 WAVELibrary
Library                 WAVELibrary.Cropping

Suite Setup             Setup chromedriver

*** Variables ***
########################################################################
#                           ENVIRONMENTS
########################################################################
#${SERVER}               https://booking.airasia.com
${SERVER}               https://assistive.airasia.com/h5/assistive/r/booking/
${BROWSER}              chrome
${DELAY}                0
@{SUMMARY_WAVE_REPORT}  COMPLETE WAVE REPORT \n ${LINE_SEPARATOR}
${LINE_SEPARATOR}       ====================================
${ERROR_ALERT_MESSAGE}

*** Keywords ***
########################################################################
#                           CONTROLS
########################################################################
Setup chromedriver
  Set Environment Variable  webdriver.chrome.driver  ${EXECDIR}/chromedriver.exe
  ${chrome options}=    Evaluate            sys.modules['selenium.webdriver'].ChromeOptions()   sys, selenium.webdriver
  Call Method           ${chrome options}   add_extension                                       C:\\Users\\user\\Desktop\\AirAsiaMobileAutomation\\testsuite\\WAVE Evaluation Tool.crx
  Create Webdriver      Chrome              chrome_options=${chrome options}
  Go To           chrome://extensions/
  Click Element   //*[@id="footer-section"]/a[2]
  Click Element   //*[@id="command-jbbplnpkjmmeebjpijfedlgcdilocofh-_execute_browser_action"]/div/div/div/span[2]/span/span
  Press Key       //*[@id="command-jbbplnpkjmmeebjpijfedlgcdilocofh-_execute_browser_action"]/div/div/div/span[2]/span/span        \\2
  Click Element   //*[@id="extension-commands-dismiss"]
  Extra Setup For Testing


Scroll To Element
    [Arguments]    ${locator}
    Selenium2Library.Wait Until Page Contains Element    ${locator}
    Sleep    2
    ${xPozition}=    Selenium2Library.Get Horizontal Position    ${locator}
    ${yPozition}=    Selenium2Library.Get Vertical Position    ${locator}
    Sleep    1
    Scroll Page To Location    ${xPozition}    ${yPozition}
    Sleep    1

Scroll Page To Location
    [Arguments]    ${x_location}    ${y_location}
    [Documentation]    Scroll the document to the specified coordinates
    ...
    ...    [Arguments]  [Description]
    ...    - xpos  Number  Required. The coordinate to scroll to, along the x-axis (horizontal), in pixels
    ...    - ypos  Number  Required. The coordinate to scroll to, along the y-axis (vertical), in pixels
    Execute Java Script    window.scrollTo(${x_location},${y_location})

########################################################################
#           WAVE ACCESSIBILITY CONTROLS
########################################################################
Extra Setup For Testing
    Remove File     result.json
    Create File     result.json

Toggle Wave Extension
    Press Key       //body          \\2
    Sleep           2

Get Wave Summary Report
    ${wave_summary_report}=    Set Variable     SUMMARY \n Wave has detected the following :
    @{items}    Create List     error    alert   feature    structure   html5   contrast
    :FOR    ${element}    IN    @{items}
    \    ${result}=                     Execute Javascript      return wave.report.iconlist.${element}.count;
    \    ${wave_summary_report}=        Catenate    SEPARATOR=\n    ${wave_summary_report}     - ${result} ${element}
    \    Run Keyword If     '${element}'=='error'   Create Error Alert Message      ${element}      ${result}
    \    Run Keyword If     '${element}'=='alert'   Create Error Alert Message      ${element}      ${result}
    ${window_title}=    Get Window Titles
    ${wave_summary_report}=    Catenate    SEPARATOR=\n    ${LINE_SEPARATOR} \n ${window_title}     ${LINE_SEPARATOR} \n ${wave_summary_report}
    Log     ${wave_summary_report}
    [Return]  ${wave_summary_report}

Get Wave Details Report
    ${page_wave_detail_report}=     Set variable    \nDETAILS
    @{items}    Create List     error    alert   feature    structure   html5   contrast
    :FOR    ${element}    IN    @{items}
    \    ${result}=     Get Each Wave Detail Report    ${element}
    \    ${page_wave_detail_report}=    Catenate    SEPARATOR=\n    ${page_wave_detail_report}      - ${result}
    [Return]  ${page_wave_detail_report}

Get Each Wave Detail Report
    [Arguments]    ${element}
    ${wave_detail_report}=  Set Variable    ${element} :
    ${result}=      Execute Javascript      return Object.entries(wave.report.iconlist.${ELEMENT}.items).length;
    : FOR   ${index}    IN RANGE    0    ${result}
    \       ${count}=                   Execute Javascript      return Object.entries(wave.report.iconlist.${element}.items)[${index}][1].count
    \       ${desc}=                    Execute Javascript      return Object.entries(wave.report.iconlist.${element}.items)[${index}][1].description
    \       ${wave_detail_report}=      Catenate    SEPARATOR=\n    ${wave_detail_report}   -- ${count} x ${desc}
    \       ${xpaths}=                  Get xpath violation        ${ELEMENT}     ${index}
    \       ${wave_detail_report}=      Catenate    SEPARATOR=\n    ${wave_detail_report}   ${xpaths}
    Log     ${wave_detail_report}
    [Return]  ${wave_detail_report}

Create Error Alert Message
    [Arguments]  ${element}     ${count}
    ${window_title}=    Get Window Titles
    ${message}=     Run Keyword If      '${count}'!='0'     Catenate        SEPARATOR=\n        ${ERROR_ALERT_MESSAGE}      There is ${count} ${element} found at page ${window_title}
    Run Keyword If      '${count}'!='0'     Set Global Variable     ${ERROR_ALERT_MESSAGE}      ${message}

Get xpath violation
    [Arguments]    ${element}       ${details_row}
    ${xpaths}=      Set Variable
    ${count_xpath}=                     Execute Javascript      return Object.entries(wave.report.iconlist.${element}.items)[${details_row}][1].xpaths.length
    : FOR   ${index}    IN RANGE    0    ${count_xpath}
    \       ${result}=      Execute Javascript   return Object.entries(wave.report.iconlist.${element}.items)[${details_row}][1].xpaths[${index}]
    \       ${xpaths}=      Catenate    ${xpaths}   --- ${result} \n
    [Return]            ${xpaths}

Complete WAVE Report
    [Arguments]  ${value}
    ${COMPLETE_WAVE_REPORT}=    Set Variable    ${LINE_SEPARATOR}
    :FOR    ${SUMMARY}    IN    @{SUMMARY_WAVE_REPORT}
    \   ${COMPLETE_WAVE_REPORT}=    Catenate    SEPARATOR=\n    ${COMPLETE_WAVE_REPORT}     ${SUMMARY}
    Log     ${COMPLETE_WAVE_REPORT}
    Generate Complete JSON Reporting
    [Return]  ${COMPLETE_WAVE_REPORT}

Generate Complete JSON Reporting
    ${content}=     Get File        result.json
    ${report}=      Catenate        {"page" : [${content}]}
    ${report}=      Replace String      ${report}         {"page" : [,      {"page" : [
    Remove File     result.json
    Create File     result.json
    Append To File  result.json          ${report}

Generate JSON Reporting
    ${result}=      Execute Javascript      return JSON.stringify(wave.report.iconlist);
    ${title}=       Execute Javascript      return wave.report.title
    Log             ${result}
    ${content}=     Get File        result.json
    Remove File     result.json
    ${result}=      Catenate        ,{"title" : "${title}", "report" : ${result}}\n       ${content}
    Create File     result.json
    Append To File  result.json          ${result}

Get Page WAVE Accessibility Report
    [Arguments]  ${value}
    Toggle Wave Extension
    ${result}=      Get Wave Summary Report
    Append To List  ${SUMMARY_WAVE_REPORT}      ${result}
    ${result}=      Get Wave Details Report
    Append To List  ${SUMMARY_WAVE_REPORT}      ${result}
    Generate JSON Reporting
    Toggle Wave Extension

Failed If Found Error Or Alert
    ${number_of_message}=   Get Length      ${ERROR_ALERT_MESSAGE}
    Run Keyword If      '${number_of_message}'!='0'     Fail    ${ERROR_ALERT_MESSAGE}

########################################################################
#           TEST STEPS
########################################################################
Step1 - Search Flight
    Get Page WAVE Accessibility Report  Yes
    Select From List    //*[@id="airAsiaSearch.fromInput"]  Kuala Lumpur (KUL)
    Sleep               2
    Select From List    //*[@id="airAsiaSearch.toInput"]    Singapore (SIN)
    Sleep               2
    Click Element       //*[@id="un_content"]/div[2]/form/input[2]

Step2 - Select Flight
    Get Page WAVE Accessibility Report  Yes
    Click Element       //*[@id="un_content"]/div[3]/div[1]/div[3]/table/tbody/tr[1]/td[4]/div[1]/form/a/div[1]/div[1]
    Sleep               2
    Scroll To Element   //*[@id="un_content"]/div[3]/div[2]/div[3]/table/tbody/tr[1]/td[4]/div[1]/form/a/div[1]/div[1]
    Click Element       //*[@id="un_content"]/div[3]/div[2]/div[3]/table/tbody/tr[1]/td[4]/div[1]/form/a/div[1]/div[1]
    Sleep               2
    Scroll To Element   //*[@id="un_content"]/div[5]/form/input[3]
    Click Element       //*[@id="un_content"]/div[5]/form/input[3]

Step3 - Login Page
    Get Page WAVE Accessibility Report  Yes
    Click Element       //*[@id="un_content"]/div[1]/form/input[3]

Step4 - Guest Details
    Get Page WAVE Accessibility Report  Yes
    Input Text          //*[@id="airAsiaPassengers[0].Name.First"]          Masenanda
    Sleep               4
    Input Text          //*[@id="airAsiaPassengers[0].Name.Last"]           Andrean
    Sleep               3
    Select From List    //*[@id="airAsiaPassengers[0].Info.Nationality"]    Indonesia
    Sleep               3
    Select From List    //*[@id="airAsiaPassengers[0].date_of_birth_day_0"]     21
    Sleep               3
    Select From List    //*[@id="airAsiaPassengers[0].date_of_birth_month_0"]   January
    Sleep               3
    Select From List    //*[@id="airAsiaPassengers[0].date_of_birth_year_0"]    1991
    Sleep               3
    Scroll To Element   //*[@id="un_content"]/div[3]/form/input[3]
    Click Element       //*[@id="un_content"]/div[3]/form/input[3]

Step - Finalize
    Complete WAVE Report                Yes
    Failed If Found Error Or Alert


########################################################################
#                           TEST SUITE
########################################################################
Suite Teardown
    Close all browsers

*** Test Cases ***
########################################################################
#                           TEST CASES
########################################################################
Test Access WAVE Object
    Go To           ${SERVER}
    Sleep           2


TC - Scenario 1
    Step1 - Search Flight
    Step2 - Select Flight
    Step3 - Login Page
    #Step4 - Guest Details
    Step - Finalize
    [Teardown]  Suite Teardown