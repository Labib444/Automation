

from selenium.webdriver.remote.webdriver import WebElement
from strategy.implementStrategy import ImplementStrategy
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import StaleElementReferenceException, TimeoutException, NoSuchElementException

class Input:
    def __init__(self, driver :WebDriver, selection_type, selection_value, implimentAction :ImplementStrategy):
        self.selection_type  = selection_type
        self.selection_value = selection_value
        self.implimentAction = implimentAction
        self.driver = driver

    def initialize(self):
        WebDriverWait(
            driver=self.driver,
            timeout=5
        ).until(
            EC.visibility_of_element_located((self.selection_type, self.selection_value))
        )

    def operation(self):
        pass

    def finalize(self):
        pass

    def implement(self):
        self.initialize()
        trys = 2
        while(True):
            try:
                self.operation()
            except StaleElementReferenceException as se:
                continue
            except TimeoutException as te:
                if trys == 0:
                    break
                trys -= 1
                continue

class InputTextField(Input):
    def __init__(self, driver :WebDriver, selection_type, selection_value, implimentAction :ImplementStrategy):
        super().__init__(driver, selection_type, selection_value, implimentAction)
    def operation(self):
        self.implimentAction.implement()

#class InputCheckBox(Input):








