import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { getGlobalContext } from '../entryability/EntryAbility';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JWSUtil } from './JwsUtil';
import { FinishStatus, PurchaseOrderPayload } from './PurchaseOrderPayload';

export interface ProductType {
  id: string,
  name: string,
  description: string,
  price: number,
  productType: iap.ProductType
}

export const productTypes: ProductType[] = [
  {
    id: 'test_product_1',
    name: 'Wearable',
    description: 'Huawei Watch 5',
    price: 10.99,
    productType: iap.ProductType.CONSUMABLE
  },
  {
    id: 'test_product_2',
    name: 'Phone',
    description: 'Huawei Phone',
    price: 20.99,
    productType: iap.ProductType.CONSUMABLE
  }
];

@Component
@Entry
struct PurchaseProduct {
  private context: common.UIAbilityContext | undefined = undefined;

  aboutToAppear() {
    this.context = getGlobalContext();
  }

  async handlePurchase(product: ProductType) {
    if (!this.context) {
      hilog.error(0, 'IapCreatePurchase', 'UIAbilityContext is not ready yet');
      return;
    }

    const result = await createPurchase(this.context, product.id, product.productType)

    await dealPurchaseOrderJws(result.purchaseData, this.context)

  }

  build() {
    Column() {
      Swiper() {
        ForEach(
          productTypes,
          (item: ProductType) => {
            Swiper() {
              Column() {
                Text(item.name)
                  .fontSize(22)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Text(item.description)
                  .fontSize(16)
                  .fontColor('#DDDDDD')
                  .margin({ bottom: 12 })

                Text(`$${item.price}`)
                  .fontSize(20)
                  .fontColor('#FFD700')
                  .margin({ bottom: 24 })

                Button('BUY NOW')
                  .width(140)
                  .height(40)
                  .backgroundColor('#2E7D32')
                  .fontColor(Color.White)
                  .onClick(() => this.handlePurchase(item))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          },
          (item: ProductType) => item.id
        )

      }
      .loop(false)
      .indicator(true)
      .width('100%')
      .height('100%')

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}

@Builder
export function PurchaseProductBuilder() {
  PurchaseProduct()
}

async function createPurchase(
  context: common.UIAbilityContext,
  productId: string,
  productType: iap.ProductType,
  developerPayload: string = 'payload'
): Promise<iap.CreatePurchaseResult> {
  try {
    const result = await iap.createPurchase(context, {
      productId,
      productType,
      developerPayload
    });
    return result;
  } catch (e) {
    throw new Error(`createPurchase failed: ${e}`);
  }
}

async function finishPurchase(
  context: common.UIAbilityContext,
  productType: iap.ProductType,
  purchaseToken: string,
  purchaseOrderId: string
): Promise<boolean> {
  try {
    await iap.finishPurchase(context, {
      productType,
      purchaseToken,
      purchaseOrderId
    });
    return true;
  } catch (e) {
    hilog.error(0, 'iap', `finishPurchase failed: ${e}`);
    return false;
  }
}

async function dealPurchaseOrderJws(
  jwsPurchaseOrder: string,
  context: common.UIAbilityContext
): Promise<void> {

  const payloadStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
  if (!payloadStr) {
    hilog.warn(0, 'iap', 'JWS decode failed');
    return;
  }

  const payload = safeJsonParse<PurchaseOrderPayload>(payloadStr);

  if (!payload) {
    hilog.warn(0, 'iap', 'PurchaseOrder payload parse failed');
    return;
  }

  if (!payload.needFinish || payload.finishStatus === FinishStatus.FINISHED) {
    return;
  }

  try {
    const ok = await finishPurchase(
      context,
      Number(payload.productType),
      payload.purchaseToken,
      payload.purchaseOrderId
    ) as boolean;

    hilog.info(
      0,
      'iap',
      `finishPurchase result=${ok} productId=${payload.productId}`
    );

  } catch (e) {
    hilog.error(
      0,
      'iap',
      `finishPurchase failed productId=${payload.productId}, error=${JSON.stringify(e)}`
    );
  }
}

function safeJsonParse<T>(json: string): T | undefined {
  try {
    return JSON.parse(json) as T;
  } catch (e) {
    hilog.error(0, 'IapManager', `JSON parse failed: ${JSON.stringify(e)}`);
    return undefined;
  }
}

