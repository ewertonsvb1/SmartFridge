package com.smartfridge.backend.user;

import com.smartfridge.backend.security.AuthenticatedUserService;
import com.smartfridge.backend.user.dto.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final AuthenticatedUserService authenticatedUserService;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public UserResponse me() {
        return userMapper.toResponse(authenticatedUserService.getCurrentUser());
    }
}
