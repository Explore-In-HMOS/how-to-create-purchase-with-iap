import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { getGlobalContext } from '../entryability/EntryAbility';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface ProductType {
  name: string,
  description: string,
  price: number,
}

export const productTypes: ProductType[] = [
  { name: 'Wearable', description: 'Huawei Watch 5', price: 10.99 },
  { name: 'Phone', description: 'Huawei Phone', price: 20.99 },
];

@Component
@Entry
struct PurchaseProduct {

  private context: common.UIAbilityContext | undefined = undefined;

  aboutToAppear() {
    this.context = getGlobalContext();
  }

  createPurchase(product: ProductType) {
    if (!this.context) {
      hilog.error(0,'IapCreatePurchase','UIAbilityContext is not ready yet');
      return;
    }

    const param: iap.PurchaseParameter = {
      productType: iap.ProductType.CONSUMABLE,
      productId: 'test_product_1',
      developerPayload: `purchase_${product.name}`
    };

    iap.createPurchase(this.context, param)
      .then(data => {
        console.info('Purchase success: ' + data.purchaseData);
      })
      .catch((err: BusinessError) => {
        console.error('Purchase failed: ' + err.code + ' ' + err.message);
      });
  }

  build() {
    Column() {
      Swiper() {
        ForEach(productTypes, (item: ProductType) => {
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
                .backgroundColor('#4CAF50')
                .fontColor(Color.White)
                .onClick(() => this.createPurchase(item))

            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

          }
        })

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
