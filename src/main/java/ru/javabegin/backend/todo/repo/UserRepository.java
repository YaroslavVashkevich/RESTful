package ru.javabegin.backend.todo.repo;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ru.javabegin.backend.todo.entity.User;

public interface UserRepository extends JpaRepository<User, Long> {

    User findByEmail(String email);

    User findByUsername(String username);

    @Query("""
            SELECT u FROM User u where
            (:id is null or u.id = :id) and
            (:email is null or :email='' or lower(u.email) like lower(concat('%', :email,'%'))) and
            (:username is null or :username='' or lower(u.username) like lower(concat('%', :username,'%')))
            """)
    Page<User> findByParams(@Param("id") Long id,
                            @Param("email") String email,
                            @Param("username") String username,
                            Pageable pageable
    );
}
