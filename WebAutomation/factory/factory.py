

from enum import Enum
from strategy.waitStrategy import *
from strategy.actionStrategy import *
from strategy.implementStrategy import *
from webinput.input import *
from selenium.webdriver.remote.webdriver import WebDriver

class WAIT_ENUM(Enum):
    WAIT_UNTIL_EXISTS = "WaitUntilExists",
    WAIT_UNTIL_VALUE =  "WaitUntilValue"

class ACTION_ENUM(Enum):
    READ_STRATEGY = "ReadStrategy"
    WRITE_STRATEGY = "WriteStrategy"
    EDIT_STRATEGY = "EditStrategy"

class FACTORY_ENUM(Enum):
    WAIT_FACTORY = "WaitFactory",
    ACTION_FACTORY = "ActionFactory"


class FactoryProducer:
    def __init__(self, driver :WebDriver):
        self.driver = driver
    def getFactory(self, factoryType :FACTORY_ENUM):
        match(factoryType):
            case FACTORY_ENUM.WAIT_FACTORY:
                return WaitFactory(self.driver)
            case FACTORY_ENUM.ACTION_FACTORY:
                return ActionFactory(self.driver)

class AbstractFactory:
    def getWaitObject(self, type :WAIT_ENUM, selection_type, selection_value):
        pass
    def getActionObject(self, type :WAIT_ENUM, selection_type, selection_value):
        pass

class WaitFactory(AbstractFactory):
    def __init__(self, driver :WebDriver):
        self.driver = driver

    def getWaitObject(self, type :WAIT_ENUM, selection_type, selection_value):
        match(type):
            case WAIT_ENUM.WAIT_UNTIL_EXISTS:
                return WaitUntilExists(self.driver, selection_type, selection_value)
            case WAIT_ENUM.WAIT_UNTIL_VALUE:
                return WaitUntilValue(self.driver, selection_type, selection_value)

    def getActionObject(self):
        return None


class ActionFactory(AbstractFactory):
    def __init__(self, driver :WebDriver):
        self.driver = driver

    def getWaitObject(self, type: WAIT_ENUM, selection_type, selection_value):
        return None

    def getActionObject(self, type: ACTION_ENUM, selection_type, selection_value):
        match (type):
            case ACTION_ENUM.READ_STRATEGY:
                return ReadStrategy(self, selection_type, selection_value)
            case ACTION_ENUM.WRITE_STRATEGY:
                return WriteStrategy(self, selection_type, selection_value)
            case ACTION_ENUM.EDIT_STRATEGY:
                return EditStrategy(self, selection_type, selection_value)


