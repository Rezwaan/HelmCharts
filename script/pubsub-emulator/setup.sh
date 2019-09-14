#!/bin/sh

publisher.py project create SwyftOrderCreated
publisher.py project create SwyftOrderUpdated

subscriber.py project create SwyftOrderCreated swyft-order-created
subscriber.py project create SwyftOrderUpdated swyft-order-updated

publisher.py project create DomeOrderUpdated
publisher.py project create DomeStoreUpdated
publisher.py project create DomeCatalogUpdated
