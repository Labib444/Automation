import selenium
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.remote.webelement import WebElement
from selenium.webdriver.common.alert import Alert
from selenium.common.exceptions import StaleElementReferenceException, TimeoutException
from pages.cashDepositPage.constants import *
import time
import os
import random

from Factory.webInputFactory import WebInputFactory
from enums.webInputEnums import WebInputEnum
from enum import Enum


from strategy.waitStrategy import *
from strategy.actionStrategy import *
from strategy.implementStrategy import *
from webinput.input import Input, InputTextField


class INPUTS(Enum):
    MEMBER_NAME = "Umyakhing Marma"
    MEMBER_NO = 8320
    VOUCHER_NO = 1107651
    LOG_FILE = r"C:\Users\labib\PycharmProjects\pythonProject\logs\log.txt"
    DELAY = round(random.uniform(0.2, 0.4), 1)
    LOGIN_USER_ID = "5"
    PASSWORD = "AAAAAAAA"
    TIME_OUT_EXCEPTION_TRYS = 2
    DRIVER_TIME_DELAY = 30

class CashDeposit(webdriver.Edge):

    def __init__(self, driver_path=DRIVER_URL, tearDown = False ):
        self.driver_path = driver_path
        self.tearDown = tearDown
        super(CashDeposit, self).__init__(self.driver_path)

    def implicitWait(self):
        self.implicitly_wait(10)

    def do(self):
        self.get(PAGE_URL)
        self.maximize_window()
        self.implicitWait()
        self.signIn(name=INPUTS.LOGIN_USER_ID.value, passw=INPUTS.PASSWORD.value)
        self.goToAccounts()
        self.openCashDeposit()
        self.givingRequiredInputs()
        self.logout()

    # def signIn(self, name, passw):
    #     username = self.find_element(By.ID, "username")
    #     password = self.find_element(By.ID, "password")
    #     submit = self.find_element(By.ID, "submit")
    #     username.send_keys(name)
    #     password.send_keys(passw)
    #     submit.click()

    def signIn(self, name, passw):
        waitAction = WaitUntilExists(self, By.ID, "username")
        action = WriteStrategy(self, By.ID, "username", name)
        implement = BasicImplement(self, By.ID, "username", waitAction, action)
        usernameField = InputTextField(self, By.ID, "username", implement)
        usernameField.implement()

    def goToAccounts(self):
        self.implicitWait()
        accounts = self.find_element(By.CLASS_NAME, "p-3")
        if accounts.text == "Accounts Service":
            accounts.click()

    def openCashDeposit(self):
        self.get(PAGE_URL+"accounting/cash-deposit")
        self.implicitWait()
        time.sleep(INPUTS.DELAY.value)

    def givingRequiredInputs(self):
        factory = WebInputFactory(self)

        memberIdInput = factory.getInputObject(WebInputEnum.TextInput, By.ID, "MemberNo")
        voucherInput = factory.getInputObject(WebInputEnum.TextInput, By.ID, "VoucherNo")

        memberIdInput.implement(INPUTS.MEMBER_NO.value)
        #self.waitForText(By.ID, "labelMemberName", "Umyakhing Marma")
        cards = self.find_elements(By.CLASS_NAME, "card-body")[0]
        formGroups = cards.find_elements(By.CLASS_NAME, "form-group")
        WebDriverWait(
            driver=self,
            timeout=120
        ).until(
            #lambda x: formGroups[2].find_elements(By.TAG_NAME, "label")[1].text.strip() == INPUTS.MEMBER_NAME.value
            lambda x: formGroups[2].find_elements(By.TAG_NAME, "label")[1].text.strip() != ''
        )
        voucherInput.implement(INPUTS.VOUCHER_NO.value)

        glCodeList = ["20201001", "20211001", "10121002", "40401002"]
        amountList = ["50.00", "50.00", "2200.00", "300.00"]

        #glCodeList = ["20201001","20211001","40452005","40431008","20239001","20231005","40452001","20236002","20235002", "40401002"]
        #amountList = ["100.00","1100.00","60.00","60.00","60.00","60.00","20.00","20.00","20.00","100.00"]
        #waitAmountList = ["0.00", "0.00", "17,952.00", "1,372.00"]

        self.writeFile(INPUTS.LOG_FILE.value, "GLCode\t\tAmount\t\t\tAccNo\n")
        for i in range( len(glCodeList) ):
            time.sleep(INPUTS.DELAY.value)
            glcodeInput = factory.getInputObject(WebInputEnum.TextInput, By.ID, "GLAccNo"+str(i))
            amountInput = factory.getInputObject(WebInputEnum.TextInput, By.ID, "TrnAmount"+str(i))
            if glCodeList[i] != "40401002":
                glcodeInput.implement(glCodeList[i])
                if i != 0 and i != 1:
                    time.sleep(INPUTS.DELAY.value)
                    self.waitUntilNotEmpty(By.ID, "TrnAmount"+str(i))
                else:
                    time.sleep(INPUTS.DELAY.value)
                    self.waitUntilEmpty(i)
                amountInput.implement(amountList[i])
            else:
                self.find_element(By.ID, "GLAccNo"+str(i)).send_keys(Keys.ENTER)
                if i != 0 and i != 1:
                    time.sleep(INPUTS.DELAY.value)
                    self.waitUntilNotEmpty(By.ID, "TrnAmount"+str(i))
                else:
                    time.sleep(INPUTS.DELAY.value)
                    self.waitUntilEmpty(i)
                amountInput.implement(amountList[i])

            formArray = self.find_element(By.ID, "myDepositList" + str(i))
            accNoInput = formArray.find_element(By.CSS_SELECTOR, "input[formcontrolname=AccNo]")
            self.writeFile(INPUTS.LOG_FILE.value,
                           glcodeInput.getInputVal(self) + "\t" +
                           amountInput.getInputVal(self) + "\t\t" +
                           accNoInput.get_attribute("value") + "\n"
                           )


        self.writeFile(INPUTS.LOG_FILE.value, "\n")

    def logout(self):
        time.sleep(1.5)
        self.find_element(By.CLASS_NAME, "pro-user-name").click()
        self.find_element(By.CSS_SELECTOR, 'a[href="/sign-in"]').click()

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.tearDown:
            self.quit()


    def waitForText(self, selection_type, selection_value, findText):
        trys = INPUTS.TIME_OUT_EXCEPTION_TRYS.value
        while (True):
            try:
                WebDriverWait(
                    driver=self,
                    timeout=INPUTS.DRIVER_TIME_DELAY.value
                ).until(
                    EC.text_to_be_present_in_element(
                        (selection_type, selection_value), findText
                    )
                )
                break
            except StaleElementReferenceException as e:
                print("Trying...")
                continue
            except TimeoutException as te:
                print("Timed Out Trying...")
                if trys == 0:
                    print("Trying Failed...Timed out for too long.")
                    break
                trys -= 1
                continue


    def waitUntilNotEmpty(self, a, b):
        trys = INPUTS.TIME_OUT_EXCEPTION_TRYS.value
        while (True):
            try:
                WebDriverWait(
                    driver=self,
                    timeout=INPUTS.DRIVER_TIME_DELAY.value
                ).until(
                     lambda x: str(self.find_element(a, b).get_attribute("value")).strip() != '0.00'
                )
                break
            except StaleElementReferenceException as e:
                print("Trying....")
                continue
            except TimeoutException as te:
                print("Timed Out Trying....")
                if trys == 0:
                    print("Trying Failed....Timed out for too long.")
                    break
                trys -= 1
                continue

    def waitUntilEmpty(self, i):
        trys = INPUTS.TIME_OUT_EXCEPTION_TRYS.value
        while(True):
            try:
                formArray = self.find_element(By.ID, "myDepositList" + str(i))
                accNoInput = formArray.find_element(By.CSS_SELECTOR, "input[formcontrolname=AccNo]")
                WebDriverWait(
                    driver=self,
                    timeout=INPUTS.DRIVER_TIME_DELAY.value
                ).until(
                    lambda x: accNoInput.is_displayed() and len(str(accNoInput.get_attribute("value"))) != 0
                )
                break
            except StaleElementReferenceException as e:
                print("Trying...")
                continue
            except TimeoutException as te:
                print("Timed Out Trying...")
                if trys == 0:
                    print("Trying Failed...Timed out for too long.")
                    break
                trys -= 1
                continue

    def customFunc(self, selection_type, selection_value):
        trys = INPUTS.TIME_OUT_EXCEPTION_TRYS.value
        while (True):
            try:
                length = len(str(self.find_element(selection_type, selection_value).text).strip())
                if length == 0:
                    return False
                else:
                    return True
                break
            except StaleElementReferenceException as e:
                print("Trying...")
                continue
            except TimeoutException as te:
                print("Timed Out Trying...")
                if trys == 0:
                    print("Trying Failed...Timed out for too long.")
                    break
                trys -= 1
                continue

    def writeFile(self, location, value):
        f = open(location, "a")
        f.write(value)
        f.close()
