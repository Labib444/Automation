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
from pages.cashDepositPage.cashDeposit import CashDeposit

with CashDeposit(tearDown=True) as cd:
    cd.do()
    time.sleep(1.5)