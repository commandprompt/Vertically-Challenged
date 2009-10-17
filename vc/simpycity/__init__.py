from simpycity import exceptions as ex
from vc import InsufficientPermissionsError as IPE, NoSuchUserError as NSUE

ex.base.add({
    'PermissionsError': IPE,
    'NoSuchUserError': NSUE
})

ex.system.add({
    'permission denied': IPE
})