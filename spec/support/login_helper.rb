def login_user(user)
  post new_user_session_path, params: { 'user[login]' => user.email,
                                        'user[password]' => user.password }
end

# eof
