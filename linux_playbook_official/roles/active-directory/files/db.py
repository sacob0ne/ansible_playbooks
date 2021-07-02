#!/usr/bin/python

import ad
import json
import socket

var = socket.gethostname()
#desc= raw_input("What's the description? ")

# Load ad credentials
file_ad = 'ad.json'
with open(file_ad) as data_ad:
    a = json.load(data_ad)

ad_c = ad.init(a['host'],a['user'] + '@' + a['user_domain'], a['pwd'])

ad.create_computer(ad_c, 'CN=' + var.upper() + ',CN=Computers,DC=SAIPEMGROUPVL,DC=RVL',
                description='test ansible')
