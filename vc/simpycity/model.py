from simpycity import context

c = context.Context() # build a Simpycity connection context

class User(c.SimpleModel()):
    
    table = [
        'id',
        'username',
        'roles'
    ]
    
    __load__ = c.Function("users.get",['id'])
    
    def can(self, role):
        """role: A text string of the role. This will be tested against the 
        list of user roles loaded from the database."""
        
        if role in self.roles:
            return True
        else:
            return False
        
        
class userauth(c.SimpleModel()):
    
    table = ['id']
    
    __load__ = c.Function("users.validate",['login','password'])
    
    is_valid = c.Function("users.is_valid",['id'])