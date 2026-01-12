
export interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  applicationId: string;
  productId: string;
  purchaseTime: number;
  productType: string;
  developerPayload?: string;
  signedTime: number;
  countryCode: string;
  price: number;
  currency: string;
  finishStatus: FinishStatus | string;
  needFinish: boolean;

  title?: string;
  icon?: Resource;
}

export enum FinishStatus {
  FINISHED = '1',
  UNFINISHED = '2'
}