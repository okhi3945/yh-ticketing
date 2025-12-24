package com.yh.ticketing.service;

import com.yh.ticketing.model.Booking;
import lombok.RequiredArgsConstructor;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class RedissonLockFacade {
    private final RedissonClient redissonClient;
    private final TicketingService ticketingService;

    public Booking reserveWithLock(Long ticketId, String userId, String userName) {
        RLock lock = redissonClient.getLock("TICKET_LOCK:" + ticketId);
        try {
            // 10초 대기, 1초 점유
            boolean available = lock.tryLock(10, 1, TimeUnit.SECONDS);
            if (!available) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "현재 예약이 몰려 처리할 수 없습니다. 다시 시도해주세요.");
            }
            return ticketingService.reserve(ticketId, userId, userName);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "시스템 오류 발생");
        } finally {
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}