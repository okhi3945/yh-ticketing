package com.yh.ticketing.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@Entity
@Table(name = "tickets")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Ticket {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private Long performanceId;
    private String seatNumber;

    @Enumerated(EnumType.STRING)
    private TicketStatus status;

    public void reserve() {
        if (this.status != TicketStatus.AVAILABLE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "이미 예약된 좌석입니다.");
        }
        this.status = TicketStatus.BOOKED;
    }
}
