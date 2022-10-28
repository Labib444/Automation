

from selenium.webdriver.remote.webdriver import WebElement

class Input:
    def __init__(self, selection_type :WebElement, selection_value :WebElement):
        self.selection_type  = selection_type
        self.selection_value = selection_value

    def initialize(self):
        pass

    def operation(self):
        pass

    def finalize(self):
        pass

    def implement(self):
        pass


#class InputTextField(Input):

#class InputCheckBox(Input):








