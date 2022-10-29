

from strategy.actionStrategy import ActionStrategy
from strategy.waitStrategy import WaitStrategy
from selenium.webdriver.remote.webdriver import WebDriver
from factory.factory import FACTORY_ENUM
from factory.factory import *

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

class BasicReadImplement(ImplementStrategy):
    def __init__(self, driver: WebDriver, selection_type, selection_value):
        super().__init__(driver, selection_type, selection_value)
    def implement(self):
        factory = FactoryProducer(self.driver)
        waitObject   = factory.getFactory(FACTORY_ENUM.WAIT_FACTORY).getWaitObject(WAIT_ENUM.WAIT_UNTIL_EXISTS, self.selection_type, self.selection_type)
        actionObject = factory.getFactory(FACTORY_ENUM.ACTION_FACTORY).getActionObject(ACTION_ENUM.READ_STRATEGY, self.selection_type, self.selection_type)
        waitObject.wait()
        return actionObject.doAction()


class BasicWriteEditImplement(ImplementStrategy):
    def __init__(self, driver: WebDriver, selection_type, selection_value, actionStrategy :ActionStrategy, waitStrategy :WaitStrategy):
        super().__init__(driver, selection_type, selection_value, actionStrategy, waitStrategy)
    def implement(self):
        self.waitStrategy.wait()
        self.actionStrategy.doAction()














