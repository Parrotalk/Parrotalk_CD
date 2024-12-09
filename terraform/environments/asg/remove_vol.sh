#!/bin/bash

# List unused volumes (available state)
echo "Finding unused volumes..."
aws ec2 describe-volumes \
    --filters Name=status,Values=available \
    --query 'Volumes[*].[VolumeId,Size]' \
    --output table

read -p "Delete unused volumes? (y/n): " confirm
if [ "$confirm" = "y" ]; then
    for volume in $(aws ec2 describe-volumes \
        --filters Name=status,Values=available \
        --query 'Volumes[*].[VolumeId]' \
        --output text); do
        echo "Deleting volume: $volume"
        aws ec2 delete-volume --volume-id $volume
    done
fi

# List snapshots owned by self
echo "Finding snapshots..."
aws ec2 describe-snapshots \
    --owner-ids self \
    --query 'Snapshots[*].[SnapshotId,StartTime,VolumeSize]' \
    --output table

read -p "Delete snapshots? (y/n): " confirm
if [ "$confirm" = "y" ]; then
    for snapshot in $(aws ec2 describe-snapshots \
        --owner-ids self \
        --query 'Snapshots[*].[SnapshotId]' \
        --output text); do
        echo "Deleting snapshot: $snapshot"
        aws ec2 delete-snapshot --snapshot-id $snapshot
    done
fi