# T002 – Improvement for UX at timeline change

**Type**: Feature
**Parent**: <!-- optional: F### or E### of the feature or epic this belongs to -->

<!--
  A task is a small change. Describe it, list the steps, then ask Claude to implement this file.
  It has no spec or plan. If it grows beyond a few steps or needs design decisions, make it a feature instead.
  Only "Summary" is required.
-->

## Summary

<!-- What should change, and why? -->
Timeline chart
Task dragging behaviour is not cool, it miss with the whole board scroll  
  
So
I want you to add below behaviour to it:  
- For the task, check when only user hold for 0.3s then it's their drag, we highlight the selected task showing it's enabled for dragging (if fast drag, we see it's the normal scroll)
- When user leave the drag, update the UI immediately rather than wait for backend to return the refresh, this is really annoying because atm, when leave the drag, the task first back to its old position, when fetch reponse come, it go with new order, it's not naturally (in case of having trouble of fetching new tasks, keep everything at its old state and show an error message (at the bottom of the screen that something went wrong). We need to block user at updating their board while waiting for the refresh by showing a waiting icon (3 dot jump up down is fine), though we still keep the UI order as previewed shows.
- Disable the default push tasks mode, gap clear mode will notify user that now every change drag others task timeline
- We allow task overlay now (maximum a task can only overlay with other 2 tasks)
- We have preview mode - dragging task would affect other task in the UI too (other task will have its re-arrangement by animations moving-up-down)  
-

## Done when
I'll test it myself manually to confirm the UX
- 

## Notes

