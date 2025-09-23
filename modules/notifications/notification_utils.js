/**
 * @param { number | string | Date } timestamp 
 * @returns { string }
 */
const getFriendlyNotifTimeString = (timestamp) => {
    if (!timestamp) return '';
    const messageTime = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - messageTime.getTime();

    // Less than 1 minute
    if (diffMs < 60000) 
        return 'Now';
    
    // Same day - show relative time
    if (messageTime.toDateString() === now.toDateString()) {
        const diffMinutes = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        
        if (diffHours > 0) {
            return `${diffHours}h`;
        } else {
            return `${diffMinutes}m`;
        }
    }
    
    // Multiple days - show relative days
    const diffDays = Math.floor(diffMs / 86400000);
    if (diffDays > 0) {
        return `${diffDays}d`;
    }
    
    // Yesterday (fallback, shouldn't reach here normally)
    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString()) 
        return 'Yesterday';
    
    // Older dates (fallback for very old notifications)
    return Qt.formatDateTime(messageTime, "MMMM dd");
};