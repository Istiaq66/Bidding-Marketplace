import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { endAuction } from './endAuction';
export { onBidCreate } from './onBidCreate';
export { onAuctionWrite } from './onAuctionWrite';