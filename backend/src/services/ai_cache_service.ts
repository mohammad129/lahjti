import crypto from 'crypto';
import { config } from '../config/env.js';

export interface CacheEntry<T = any> {
  key: string;
  value: T;
  estimatedTokens: number;
  createdAt: number;
  expiresAt: number;
  hitCount: number;
}

export class AiCacheService {
  private static instance: AiCacheService;
  private cache: Map<string, CacheEntry> = new Map();
  private maxEntries: number = 2000;
  private defaultTtlSeconds: number = config.AI_CACHE_TTL_SECONDS || 86400;

  // Telemetry metrics
  private totalHits: number = 0;
  private totalMisses: number = 0;
  private totalSavedTokens: number = 0;

  public static getInstance(): AiCacheService {
    if (!AiCacheService.instance) {
      AiCacheService.instance = new AiCacheService();
    }
    return AiCacheService.instance;
  }

  /**
   * Generates a stable deterministic cache key for AI request components
   */
  public generateKey(namespace: string, payload: Record<string, any> | string): string {
    const raw = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const hash = crypto.createHash('sha256').update(raw).digest('hex');
    return `${namespace}:${hash}`;
  }

  /**
   * Retrieve cached value if present and not expired
   */
  public get<T = any>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) {
      this.totalMisses++;
      return null;
    }

    const now = Date.now();
    if (now > entry.expiresAt) {
      this.cache.delete(key);
      this.totalMisses++;
      return null;
    }

    // Refresh LRU order and hit count
    entry.hitCount++;
    this.totalHits++;
    this.totalSavedTokens += entry.estimatedTokens;
    this.cache.delete(key);
    this.cache.set(key, entry);

    return entry.value as T;
  }

  /**
   * Store result in cache with TTL and token estimation
   */
  public set<T = any>(key: string, value: T, estimatedTokens: number = 100, ttlSeconds?: number): void {
    const ttl = ttlSeconds !== undefined ? ttlSeconds : this.defaultTtlSeconds;
    const now = Date.now();

    // Evict oldest if capacity reached
    if (this.cache.size >= this.maxEntries) {
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey) {
        this.cache.delete(oldestKey);
      }
    }

    this.cache.set(key, {
      key,
      value,
      estimatedTokens,
      createdAt: now,
      expiresAt: now + ttl * 1000,
      hitCount: 0,
    });
  }

  /**
   * Clear or invalidate entries by namespace prefix or key
   */
  public invalidate(prefixOrKey: string): void {
    for (const key of this.cache.keys()) {
      if (key.startsWith(prefixOrKey)) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Clear the entire cache
   */
  public clear(): void {
    this.cache.clear();
    this.totalHits = 0;
    this.totalMisses = 0;
    this.totalSavedTokens = 0;
  }

  /**
   * Metrics and telemetry summary
   */
  public getStats(): {
    size: number;
    hits: number;
    misses: number;
    hitRatio: number;
    savedTokens: number;
  } {
    const totalRequests = this.totalHits + this.totalMisses;
    const hitRatio = totalRequests > 0 ? this.totalHits / totalRequests : 0.0;
    return {
      size: this.cache.size,
      hits: this.totalHits,
      misses: this.totalMisses,
      hitRatio: Number(hitRatio.toFixed(3)),
      savedTokens: this.totalSavedTokens,
    };
  }
}

export const aiCacheService = AiCacheService.getInstance();
