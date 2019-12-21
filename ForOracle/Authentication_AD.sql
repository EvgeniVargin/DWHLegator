create or replace function authenticate(p_username in varchar2, p_password in varchar2 default ' ') return VARCHAR2
is
  Result varchar2(256) := 'Auth failed';

  lld dbms_ldap.SESSION;
  i Pls_Integer;
  retval pls_integer;
begin
  if length(nvl(p_password, ' ')) = 0 then
    null;
  else
    begin
      retval := -1;

      lld := dbms_ldap.init('hq-dc05.corp.skbbank.ru', 389);

      i := dbms_ldap.simple_bind_s(ld => lld,
                                   dn => 'SKB\' || p_username,
                                   passwd => nvl(p_password, ' '));

      retval := dbms_ldap.unbind_s(ld => lld);

      if i=dbms_ldap.SUCCESS then
        begin
          /*«ƒ≈—№ мы что-то делаем*/
        exception
          when others then Result := 'Link failed';
        end;
      else
        Result:='Auth failed';
      end if;
    exception
      when others then
        i := -1;
        if retval <> -1 then retval := dbms_ldap.unbind_s(ld => lld); end if;
        Result:='Auth failed';
    end;
  end if;

  return(Result);
end authenticate;
