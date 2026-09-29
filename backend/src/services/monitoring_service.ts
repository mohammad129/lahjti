export interface RequestMetric {
  method: string;
  path: string;
  statusCode: number;
  durationMs: number;
  errorCode?: string;
  timestamp: number;
}

export interface AiRequestMetric {
  feature: string;
  provider: string;
  model: string;
  success: boolean;
  inputTokens: number;
  outputTokens: number;
  durationMs: number;
  errorCode?: string;
  timestamp: number;
}

export interface TtsRequestMetric {
  provider: string;
  characterCount: number;
  cached: boolean;
  success: boolean;
  durationMs: number;
  errorCode?: string;
  timestamp: number;
}

export class MonitoringService {
  private static instance: MonitoringService;
  private startTime = Date.now();

  // Metrics counters
  private totalRequests = 0;
  private status2xxCount = 0;
  private status3xxCount = 0;
  private status4xxCount = 0;
  private status5xxCount = 0;
  private authFailuresCount = 0;
  private aiSuccessCount = 0;
  private aiFailureCount = 0;
  private ttsSuccessCount = 0;
  private ttsFailureCount = 0;
  private totalAiTokensProcessed = 0;
  private totalTtsCharsProcessed = 0;

  private latencies: number[] = [];
  private readonly maxLatencyHistory = 500;
  private errorCountsByCode: Map<string, number> = new Map();

  public static getInstance(): MonitoringService {
    if (!MonitoringService.instance) {
      MonitoringService.instance = new MonitoringService();
    }
    return MonitoringService.instance;
  }

  /**
   * Records an incoming HTTP request execution
   */
  public recordHttpRequest(metric: RequestMetric): void {
    this.totalRequests++;

    if (metric.statusCode >= 200 && metric.statusCode < 300) {
      this.status2xxCount++;
    } else if (metric.statusCode >= 300 && metric.statusCode < 400) {
      this.status3xxCount++;
    } else if (metric.statusCode >= 400 && metric.statusCode < 500) {
      this.status4xxCount++;
      if (metric.statusCode === 401 || metric.statusCode === 403) {
        this.authFailuresCount++;
      }
    } else if (metric.statusCode >= 500) {
      this.status5xxCount++;
    }

    if (metric.errorCode) {
      const current = this.errorCountsByCode.get(metric.errorCode) || 0;
      this.errorCountsByCode.set(metric.errorCode, current + 1);
    }

    this.latencies.push(metric.durationMs);
    if (this.latencies.length > this.maxLatencyHistory) {
      this.latencies.shift();
    }

    // Safe sanitized console log (No passwords, no tokens, no transcripts)
    const errNotice = metric.errorCode ? ` [ERR: ${metric.errorCode}]` : '';
    const statusColor = metric.statusCode >= 500 ? '❌' : metric.statusCode >= 400 ? '⚠️' : '✅';
    console.log(
      `${statusColor} [${new Date().toISOString()}] ${metric.method} ${metric.path} ${metric.statusCode} ${metric.durationMs.toFixed(1)}ms${errNotice}`
    );
  }

  /**
   * Records an AI Gateway request outcome
   */
  public recordAiRequest(metric: AiRequestMetric): void {
    if (metric.success) {
      this.aiSuccessCount++;
      this.totalAiTokensProcessed += metric.inputTokens + metric.outputTokens;
    } else {
      this.aiFailureCount++;
      if (metric.errorCode) {
        const current = this.errorCountsByCode.get(metric.errorCode) || 0;
        this.errorCountsByCode.set(metric.errorCode, current + 1);
      }
    }
  }

  /**
   * Records a Text-to-Speech synthesis outcome
   */
  public recordTtsRequest(metric: TtsRequestMetric): void {
    if (metric.success) {
      this.ttsSuccessCount++;
      if (!metric.cached) {
        this.totalTtsCharsProcessed += metric.characterCount;
      }
    } else {
      this.ttsFailureCount++;
      if (metric.errorCode) {
        const current = this.errorCountsByCode.get(metric.errorCode) || 0;
        this.errorCountsByCode.set(metric.errorCode, current + 1);
      }
    }
  }

  /**
   * Computes latency percentiles (average and p95)
   */
  private getLatencyStats(): { avgMs: number; p95Ms: number; minMs: number; maxMs: number } {
    if (this.latencies.length === 0) {
      return { avgMs: 0, p95Ms: 0, minMs: 0, maxMs: 0 };
    }
    const sorted = [...this.latencies].sort((a, b) => a - b);
    const sum = sorted.reduce((acc, v) => acc + v, 0);
    const avgMs = Math.round((sum / sorted.length) * 10) / 10;
    const minMs = Math.round(sorted[0] * 10) / 10;
    const maxMs = Math.round(sorted[sorted.length - 1] * 10) / 10;
    const p95Index = Math.min(sorted.length - 1, Math.floor(sorted.length * 0.95));
    const p95Ms = Math.round(sorted[p95Index] * 10) / 10;

    return { avgMs, p95Ms, minMs, maxMs };
  }

  /**
   * Returns a sanitized, safe pilot telemetry summary
   */
  public getMetricsSummary() {
    const uptimeSeconds = Math.floor((Date.now() - this.startTime) / 1000);
    const latency = this.getLatencyStats();
    const errorMap: Record<string, number> = {};
    this.errorCountsByCode.forEach((count, code) => {
      errorMap[code] = count;
    });

    const errorRatePercent =
      this.totalRequests > 0
        ? Math.round(((this.status4xxCount + this.status5xxCount) / this.totalRequests) * 1000) / 10
        : 0;

    return {
      uptimeSeconds,
      requests: {
        total: this.totalRequests,
        http2xx: this.status2xxCount,
        http3xx: this.status3xxCount,
        http4xx: this.status4xxCount,
        http5xx: this.status5xxCount,
        errorRate: `${errorRatePercent}%`,
      },
      latencyMs: latency,
      auth: {
        failures: this.authFailuresCount,
      },
      ai: {
        successCount: this.aiSuccessCount,
        failureCount: this.aiFailureCount,
        totalTokensProcessed: this.totalAiTokensProcessed,
      },
      tts: {
        successCount: this.ttsSuccessCount,
        failureCount: this.ttsFailureCount,
        totalCharsSynthesized: this.totalTtsCharsProcessed,
      },
      errorBreakdown: errorMap,
    };
  }

  /**
   * Resets metrics (useful for isolated unit tests)
   */
  public reset(): void {
    this.totalRequests = 0;
    this.status2xxCount = 0;
    this.status3xxCount = 0;
    this.status4xxCount = 0;
    this.status5xxCount = 0;
    this.authFailuresCount = 0;
    this.aiSuccessCount = 0;
    this.aiFailureCount = 0;
    this.ttsSuccessCount = 0;
    this.ttsFailureCount = 0;
    this.totalAiTokensProcessed = 0;
    this.totalTtsCharsProcessed = 0;
    this.latencies = [];
    this.errorCountsByCode.clear();
    this.startTime = Date.now();
  }
}

export const monitoringService = MonitoringService.getInstance();
