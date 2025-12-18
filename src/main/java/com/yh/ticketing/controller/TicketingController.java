package com.yh.ticketing.controller;

import com.yh.ticketing.model.Booking;
import com.yh.ticketing.service.TicketingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/tickets")
@RequiredArgsConstructor
public class TicketingController {

    private final TicketingService ticketingService;

    /**
     * 티켓 예매 API
     * POST /api/v1/tickets/{ticketId}/reserve
     */
    @PostMapping("/{ticketId}/reserve")
    public ResponseEntity<?> reserve(
            @PathVariable Long ticketId,
            @RequestParam String userId,
            @RequestParam String userName) {
        try {
            Booking booking = ticketingService.reserve(ticketId, userId, userName);
            return ResponseEntity.status(HttpStatus.CREATED).body(booking);
        } catch (Exception e) {
            // 재고 부족이나 락 획득 실패 시 에러 메시지 반환
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 내 예매 내역 조회 API
     * GET /api/v1/tickets/my?userId=user123
     */
    @GetMapping("/my")
    public ResponseEntity<List<Booking>> getMyBookings(@RequestParam String userId) {
        return ResponseEntity.ok(ticketingService.getMyBookings(userId));
    }
}