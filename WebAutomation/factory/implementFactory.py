from enum import Enum
from strategy.waitStrategy import *
from strategy.actionStrategy import *
from strategy.implementStrategy import *
from webinput.input import *
from selenium.webdriver.remote.webdriver import WebDriver
from factory import *

class IMPLEMENT_ENUM(Enum):
    BASIC_IMPLEMENT = "BasicImplement",
    BASIC_READ_IMPLEMENT = "BasicReadImplement",
    BASIC_WRITE_EDIT_IMPLEMENT = "BasicReadEditImplement",

class ImplementFactory:
    def __init__(self, driver :WebDriver):
        self.driver = driver
    def getObject(self, type :IMPLEMENT_ENUM, selection_type, selection_value):
        match(type):
            case IMPLEMENT_ENUM.BASIC_READ_IMPLEMENT:
                return BasicReadImplement(self.driver, selection_type, selection_value)
            case IMPLEMENT_ENUM.BASIC_WRITE_EDIT_IMPLEMENT:
                return BasicReadImplement(self.driver, selection_type, selection_value)






















