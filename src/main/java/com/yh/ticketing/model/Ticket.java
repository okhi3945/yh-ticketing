package com.yh.ticketing.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tickets")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Ticket {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private Integer availableQuantity;

    public void decrease() {
        if (this.availableQuantity <= 0) {
            throw new RuntimeException("매진되었습니다.");
        }
        this.availableQuantity -= 1;
    }
}