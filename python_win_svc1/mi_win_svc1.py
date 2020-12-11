import servicemanager
import socket
import sys
import win32event
import win32service
import win32serviceutil
import mi_random_data as mrd


class MiWinSvc1(win32serviceutil.ServiceFramework):
    _svc_name_ = "miGenRandomDataAW2019"
    _svc_display_name_ = "MI Data Generation (AW2019)"
    _svc_description_ = "Periodically generates new random records in AdventureWorks2019 Database"

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        rc = None
        while rc != win32event.WAIT_OBJECT_0:
            mrd.execute_stored_procedure()
            rc = win32event.WaitForSingleObject(self.hWaitStop, 2*60*1000)


if __name__ == '__main__':
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(MiWinSvc1)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(MiWinSvc1)