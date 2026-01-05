package com.yh.ticketing.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 인프라(NLB)가 서버의 생존 여부를 확인하기 위한 컨트롤러
 */
@RestController
@RequestMapping("/api/v1")
public class HealthController {

    @GetMapping("/health")
    public String healthCheck() {
        // 이 응답이 오면 NLB는 이 서버를 'Healthy'로 간주하고 트래픽을 보냄
        return "UP";
    }
}