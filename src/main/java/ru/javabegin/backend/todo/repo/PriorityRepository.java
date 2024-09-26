package ru.javabegin.backend.todo.repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.javabegin.backend.todo.entity.Priority;

import java.util.List;

@Repository
public interface PriorityRepository extends JpaRepository<Priority, Long> {

    List<Priority> findByUserEmailOrderByIdAsc(String email);

    @Query("""
            SELECT p FROM Priority p where
            (:title is null or :title='' or lower(p.title) like lower(concat('%', :title,'%')))
            and p.user.email=:email
            order by p.title asc
            """)
    List<Priority> findByTitle(@Param("title") String title, @Param("email") String email);

}
