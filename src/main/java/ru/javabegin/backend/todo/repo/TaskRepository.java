package ru.javabegin.backend.todo.repo;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.javabegin.backend.todo.entity.Task;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByUserEmailOrderByTitleAsc(String email);

    @Query("""
            SELECT t FROM Task t where
            (:title is null or :title='' or lower(t.title) like lower(concat('%', :title,'%'))) and
            (:completed is null or t.completed=:completed) and  
            (:priorityId is null or t.priority.id=:priorityId) and
            (:categoryId is null or t.category.id=:categoryId) and
            ((cast(:dateFrom as timestamp) is null or t.taskDate>=:dateFrom) and
            (cast(:dateTo as timestamp) is null or t.taskDate<=:dateTo)
            )and (t.user.email=:email)
            """)
    Page<Task> findByParams(@Param("title") String title,
                            @Param("completed") Boolean completed,
                            @Param("priorityId") Long priorityId,
                            @Param("categoryId") Long categoryId,
                            @Param("email") String email,
                            @Param("dateFrom") LocalDateTime dateFrom,
                            @Param("dateTo") LocalDateTime dateTo,
                            Pageable pageable
    );
}
