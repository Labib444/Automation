from selenium.webdriver.remote.webdriver import WebElement, WebDriver

class ActionStrategy:
    def __init__(self, driver :WebDriver, selection_type, selection_value):
        self.driver = driver
        self.selection_type = selection_type
        self.selection_value = selection_value
    def doAction(self):
        pass

class ReadStrategy(ActionStrategy):
    def __init__(self, driver :WebDriver, selection_type, selection_value):
        super().__init__(driver, selection_type, selection_value)
    def doAction(self):
        element = self.driver.find_element(self.selection_type, self.selection_value)
        return element.get_property("value")

class WriteStrategy(ActionStrategy):
    def __init__(self, driver :WebDriver, selection_type, selection_value, writeValue):
        super().__init__(driver, selection_type, selection_value)
        self.writeValue = writeValue
    def doAction(self):
        element = self.driver.find_element(self.selection_type, self.selection_value)
        element.send_keys(self.writeValue)

class EditStrategy(ActionStrategy):
    def __init__(self, driver :WebDriver, selection_type, selection_value, writeValue):
        super().__init__(driver, selection_type, selection_value)
        self.writeValue = writeValue
    def doAction(self):
        element = self.driver.find_element(self.selection_type, self.selection_value)
        element.clear()
        element.send_keys(self.writeValue)










