import ldap
import ldap.modlist as modlist

def init(server, user, password, port='389', use_ssl=False, timeout=10):

    prefix = 'ldap'
    if use_ssl is True:
        prefix = 'ldaps'
        # ask ldap to ignore certificate errors
        ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)

    if timeout:
        ldap.set_option(ldap.OPT_NETWORK_TIMEOUT, timeout)

    ldap.set_option(ldap.OPT_REFERRALS, ldap.OPT_OFF)
    server = prefix + '://' + server + ':' + port
    l = ldap.initialize(server)
    l.simple_bind_s(user, password)

    return l

def get_dn(connection, base_dn, sAMAccountName):
    filter = '(sAMAccountName=' + sAMAccountName + ')'
    attrs = ['sAMAccountName']

    try:
        result = connection.search_s(base_dn, ldap.SCOPE_SUBTREE, filter, attrs)
        return result[0][0]

    except ldap.LDAPError,e:
        print e

def create_group(connection, group_dn, description=''):

    name = ldap.dn.str2dn(group_dn)[0][0][1]
    attr = {}
    attr['objectClass'] = ['top','group']
    attr['groupType'] = '-2147483646'
    attr['cn'] = name
    attr['name'] = name
    attr['sAMAccountName'] = name
    attr['description'] = description

    try:
        ldif = modlist.addModlist(attr)
        connection.add_s(group_dn,ldif)
    except ldap.LDAPError,e:
        print e

def add_user_group(connection, domain_dn, user, group):
    user_dn = get_dn(connection, domain_dn, user)
    group_dn = get_dn(connection, domain_dn, group)

    old_members = dict()
    new_members = dict()
    new_members['member'] = user_dn
    old_members

    try:
        ldif = modlist.modifyModlist(old_members,new_members)
        connection.modify_s(group_dn, ldif)
    except ldap.LDAPError,e:
        print e

def create_computer(connection, computer_dn, description=''):

    name = ldap.dn.str2dn(computer_dn)[0][0][1]
    attr = {}
    attr['objectClass'] = \
    ['top','person','organizationalPerson','user','computer']
    attr['cn'] = name
    attr['name'] = name
    attr['sAMAccountName'] = name
    attr['userAccountControl'] = '4128'
    attr['description'] = description


    try:
        ldif = modlist.addModlist(attr)
        connection.add_s(computer_dn,ldif)
    except ldap.LDAPError,e:
        print e
