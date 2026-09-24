import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

// Заглушка iikoCloud: в MVP возвращает фейковый заказ и webhook готовит статусы.
// Боевая реализация: POST {IIKO_API_URL}/api/1/deliveryOrders/create с apiKey,
// маппинг shop.iikoId -> organizationId, items -> product iikoId.
@Injectable()
export class IikoService {
  constructor(private config: ConfigService) {}
  get enabled() { return Boolean(this.config.get('IIKO_API_KEY')) && this.config.get('IIKO_API_KEY') !== 'changeme'; }

  async createPickupOrder(input: { shopIikoId?: string | null; number: string; items: any[]; fulfillment: string }) {
    if (!this.enabled) return { iikoOrderId: `mock-${input.number}`, etaMin: 7 };
    // TODO: реальный вызов iikoCloud deliveryOrders/create
    return { iikoOrderId: `iiko-${input.number}`, etaMin: 10 };
  }

  // Webhook от кухни: статус -> наш OrderStatus. В MVP: ACCEPTED -> COOKING -> READY
  mapStatus(iikoStatus: string): 'ACCEPTED' | 'COOKING' | 'READY' | 'SERVED' {
    const s = (iikoStatus || '').toLowerCase();
    if (s.includes('ready') || s.includes('готов')) return 'READY';
    if (s.includes('cook') || s.includes('готов')) return 'COOKING';
    if (s.includes('close') || s.includes('выдан')) return 'SERVED';
    return 'ACCEPTED';
  }
}
