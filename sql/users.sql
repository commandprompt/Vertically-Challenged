CREATE SCHEMA users;

CREATE ROLE admin WITH NOINHERIT NOLOGIN;
CREATE ROLE base WITH NOINHERIT NOLOGIN;

CREATE TABLE users (
    id serial primary key,
    username text unique not null,
    password text not null,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    role text not null 
);

create type users.user AS (
    id int,
    username text,
    roles text[]
);

REVOKE SELECT (password) ON users.users FROM PUBLIC;

insert into users (username, password, role) values ('aurynn', md5('test'),'auth_level');
    
CREATE TABLE users.metadata (
    user_id int not null references users(id),
    email text not null
);


CREATE OR REPLACE FUNCTION users.roles (
    in_user_role text
) RETURNS name[] AS $body$

    SELECT ARRAY(SELECT b.rolname
                    FROM pg_catalog.pg_auth_members m
                    JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
                    WHERE m.member = r.oid) as roles
      FROM pg_catalog.pg_roles r
     WHERE r.rolname = $1;

$body$ LANGUAGE sql;
    
CREATE OR REPLACE FUNCTION users.get (
    in_user_id int
) RETURNS users.user AS $body$
    DECLARE
        v_user users.user;
    BEGIN
        SELECT id, 
               username,
               users.roles(role)
          INTO v_user 
          FROM users 
         WHERE id = in_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'get_user(in_user_id int): Specified user not found: %', in_user_id;
        ELSE
            return v_user;
        END IF;
    END;
$body$ language plpgsql;

REVOKE EXECUTE ON FUNCTION users.get(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION users.get(int) TO userauth;

CREATE OR REPLACE FUNCTION users.validate (
    in_username text,
    in_password text
) RETURNS int AS $body$

    DECLARE
        v_user users;
        v_md5 text;
    BEGIN
        
        v_md5 := md5(in_password);
        
        if v_md5 IS NULL THEN
            RETURN NULL;
        else
            
            SELECT *
              INTO v_user
              FROM users
             WHERE username = in_username
               AND pass = v_md5;
            IF NOT FOUND THEN
                RETURN NULL;
            ELSE
                RETURN v_user.id;
            END IF;
        end if;
    END;
$body$ language plpgsql SECURITY DEFINER;

REVOKE execute ON FUNCTION users.validate(text,text) FROM PUBLIC;
GRANT execute ON FUNCTION users.validate(text,text) TO userauth;


CREATE OR REPLACE FUNCTION users.is_valid (
    in_user_id int
) RETURNS boolean AS $body$
    
    SELECT EXISTS (SELECT id FROM users WHERE id = $1 AND active IS TRUE);
    
$body$ language sql;

REVOKE execute ON FUNCTION  users.is_valid(int) FROM PUBLIC;
GRANT execute ON FUNCTION users.is_valid(int) TO userauth;

CREATE OR REPLACE FUNCTION users.create_authlevel (
    in_role text
) RETURNS VOID AS $body$
    BEGIN
        
        EXECUTE 'CREATE ROLE ' || quote_literal(in_role) || ' WITH NOINHERIT NOLOGIN';
    
    END;
$body$ language plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION users.create_authlevel(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION users.create_authlevel(text) TO admin;

CREATE OR REPLACE FUNCTION users.create (
    in_username text,
    in_role text,
    in_password text
) RETURNS int AS $body$
    
    DECLARE
        v_uid int;
    
    BEGIN
        
        PERFORM username FROM users WHERE username = in_username;
        
        IF NOT FOUND THEN
            
            /* Check for the existence of this role */
            
            PERFORM rolname FROM pg_catalog.pg_roles WHERE rolname = in_role;
            
            IF FOUND THEN
                
                RETURN NULL;
                
            ELSE
                PERFORM exceptable.not_found('Role ' || quote_literal(in_role) || ' does not exist');
            END IF;
            
            /* We are good to insert */
            
            
            v_uid := nextval('users_id_seq'); /* Next value in the sequence */
            INSERT INTO users VALUES (v_uid, in_username, md5(in_password), in_role);
            
            
            
        ELSE
            PERFORM exceptable.exists('Specified user already exists.'); /* Raises an integrity violation */
        END IF;
        
        
    END;
$body$ LANGUAGE PLPGSQL;

REVOKE EXECUTE ON FUNCTION users.create(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION users.create(text, text, text) TO admin;

CREATE OR REPLACE FUNCTION users.become (
    in_user_id int,
    in_role text
) RETURNS VOID AS $$

    BEGIN
        IF users.can($1, $2) THEN
            PERFORM 'SET ROLE TO ' || quote_literal($2);
        ELSE
            PERFORM exceptable.permission_denied('User cannot become specified permission level');
        END IF;
        
    END;
$$ LANGUAGE PLPGSQL;

REVOKE EXECUTE ON FUNCTION users.become(int, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION users.become(int, text) TO base;