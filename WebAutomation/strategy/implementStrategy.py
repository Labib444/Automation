

from strategy.actionStrategy import ActionStrategy
from strategy.waitStrategy import WaitStrategy
from selenium.webdriver.remote.webdriver import WebDriver

class ImplementStrategy:
    def __init__(self, driver: WebDriver, selection_type, selection_value, actionStrategy :ActionStrategy, waitStrategy :WaitStrategy):
        self.driver = driver
        self.selection_type = selection_type
        self.selection_value = selection_value
        self.actionStrategy = actionStrategy
        self.waitStrategy = waitStrategy

    def implement(self):
        pass

class BasicImplement(ImplementStrategy):
    def __init__(self, driver: WebDriver, selection_type, selection_value, actionStrategy :ActionStrategy, waitStrategy :WaitStrategy):
        super().__init__(driver, selection_type, selection_value, actionStrategy, waitStrategy)

    def implement(self):
        self.waitStrategy.wait()
        self.actionStrategy.doAction()

















