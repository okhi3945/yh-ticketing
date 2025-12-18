package com.yh.ticketing.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bookings")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Booking {
    @Id
    private String id;
    private Long ticketId;
    private String userId;
    private String userName;
    private LocalDateTime createdAt;

    @PrePersist
    public void init() {
        this.id = UUID.randomUUID().toString();
        this.createdAt = LocalDateTime.now();
    }
}