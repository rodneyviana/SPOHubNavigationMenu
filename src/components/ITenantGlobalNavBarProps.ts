import * as SPTermStore from './../services/SPTermStoreService';

export interface ITenantGlobalNavBarProps {
    menuItems: SPTermStore.ISPTermObject[];
    siteId: string | undefined;
}
