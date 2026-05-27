import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { endAuction } from './endAuction';
export { auctionEndingSoon } from './auctionEndingSoon';
export { onBidCreate } from './onBidCreate';
export { onAuctionCreate } from './onAuctionCreate';
export { onAuctionWrite } from './onAuctionWrite';