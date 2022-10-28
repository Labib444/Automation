
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.remote.webdriver import WebDriver


class WaitStrategy:
    def __init__(self, driver :WebDriver, selection_type, selection_value):
        self.driver = driver
        self.selection_type = selection_type
        self.selection_value = selection_value

    def wait(self):
        pass

class WaitUntilExists:
    def __init__(self, driver, selection_type, selection_value):
        super().__init__(driver, selection_type, selection_value)

    def wait(self):
        WebDriverWait(
            driver=self.driver,
            timeout=5
        ).until(
            EC.visibility_of_element_located((self.selection_type, self.selection_value))
        )

class WaitUntilValue:
    def __init__(self, driver, selection_type, selection_value, searchText):
        super().__init__(driver, selection_type, selection_value)
        self.searchText = searchText

    def wait(self):
        WebDriverWait(
            driver=self.driver,
            timeout=5
        ).until(
            EC.text_to_be_present_in_element( (self.selection_type, self.selection_value), self.searchText)
        )











