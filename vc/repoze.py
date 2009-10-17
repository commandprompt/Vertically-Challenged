#from vc.model import user
from pylons import request, config
import paste.request

from simpycity import model
from simpycity.core import FunctionError
import logging

log = logging.getLogger(__name__)

class AnonymousAuthTktIdentifier(object):
    
    def identify(self, environ):
        i = environ['repoze.who.plugins']['auth_tkt'].identify(environ)
        
        if i:
            #Not anonymous
            return i
        else: 
            # Is anonymous - return a basic anonymousness.
            return {"repoze.who.userid": anonymous_user_id}
            
    def forget(self, environ, identity):
        return environ['repoze.who.plugins']['auth_tkt'].forget(environ, identity)
    def remember(self, environ, identity):
        return environ['repoze.who.plugins']['auth_tkt'].remember(environ, identity)

class MetadataProvider(object):
    
    """Provides metadata (a user object) for the user ID.
    This populates the "model" entry in the repoze.who.identity dict with
    the model of the present user.
    
    This is *then* used by the AuthenticatedModel system.
    """
    
    def add_metadata(self, environ, identity):
        """This adds metadata, in terms of a model, to the identity
        dict for use by downstream applications.
        """
        
        
        if userid:
            log.debug("userid of %s" % userid)
            try:
                from vc.model import user
                u = user.user(userid)
                u.become(u.role)
            except FunctionError, e:
                if "model" in identity:
                    del identity['model']
                return None
            identity['model'] = u
        
        
class RedirectingChallenger(object):

    def challenge(cls, environ, status, app_headers, forget_headers):

        log.debug ("Handling the challenge.")
        """
        Challenge creates a simple callable that only redirects the user to 
        the login page. It does nothing else of interest.

        The login page is assumed to be defined by the Pylons routing system,
        and handled in Pylons itself.
        """

        def redirector(status, start_response, exc_info=None):

            """A simple WSGI app; just sets the 302 headers, 
               and returns.
            """
            session['login.pre_uri'] = environ['PATH_INFO']
            session.save()
            start_response('302 Found',[("Location","/login"),("Content-type","text")])
            return []
        return redirector

class VcBasePlugin(object):
    
    

def make_plugin (
    backing=None,
    login_path=None,
    ):
    
    if backing is None:
        raise ValueError('Must declare an SQL backing (eg simpycity)')
    
    if login_path is None:
        raise ValueError("Must declare a login path for Redirecting Challenger")
        
    plugin = VcBasePlugin(backing, login_path)
    return plugin

def needs(perm):
    def wrap(func):
        def decorate(*args, **kwargs):
            if h.user_model.can(perm):
                return func(*args, **kwargs)
        return decorate
    return wrap