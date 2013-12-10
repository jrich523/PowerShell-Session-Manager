using System;
using System.ComponentModel;
using System.Net;
using System.Net.Sockets;
using System.IO;

namespace DoWork
{
    public class MonitorCommand
    {
        private BackgroundWorker bw;


        public event CommandEventHandler OnCommand;
        
        #region public members
        public MonitorCommand()
        {
            this.bw = new BackgroundWorker { WorkerReportsProgress = true, WorkerSupportsCancellation = true };
            this.bw.DoWork += new DoWorkEventHandler(this.BackgroundWorker_DoWork);
            this.bw.ProgressChanged += new ProgressChangedEventHandler(this.BackgroundWorker_Progress);
            this.bw.RunWorkerCompleted += new RunWorkerCompletedEventHandler(this.BackgroundWorker_Completed);
        }
        public bool IsRunning { get; set; }
        public int Port { get; set; }
        public bool Start(int port)
        {
            this.Port = port;
            if (this.OnCommand == null || this.IsRunning)
            {
                return false;
            }
            try
            {
                this.bw.RunWorkerAsync(this.Port);
                this.IsRunning = true;
                return true;
            }
            catch (Exception)
            {
                    
            }
            return false;

        }
        public bool Stop()
        {
            try
            {
                //connect and send close (blank line)
                var tcpclient = new TcpClient("localhost", this.Port);
                var stream = tcpclient.GetStream();
                var writer = new StreamWriter(stream);
                writer.Write("");
                return true;
            }
            catch (Exception)
            {

                return false;
            }
        }
        #endregion
        
        #region worker events
        private void BackgroundWorker_DoWork(object sender, DoWorkEventArgs eventArgs)
        {
            var worker = sender as BackgroundWorker;
            var port = (int)eventArgs.Argument;
            if (worker != null)
            {
                string line;
                var listener = new TcpListener(IPAddress.Any, port);
                listener.Start();
                do
                {
                    var client = listener.AcceptTcpClient(); //blocks
                    var stream = client.GetStream();
                    var reader = new StreamReader(stream);
                    line = reader.ReadLine(); //assume single command, safe?
                    if (!string.IsNullOrEmpty(line))
                    {
                        var RemoteEndPoint = (IPEndPoint)client.Client.RemoteEndPoint;
                        string hostname=Dns.GetHostEntry(RemoteEndPoint.Address.ToString()).HostName;
                        line = hostname + ";" + line;
                        worker.ReportProgress(0, line);
                    }
                    reader.Dispose();
                    stream.Dispose();
                    client.Close();
                }
                while (!string.IsNullOrEmpty(line));
                listener.Stop();
            }
        }
        private void BackgroundWorker_Progress(object sender, ProgressChangedEventArgs eventArgs)
        {
            if (OnCommand != null)
            {
                //expects cmd:value
                string[] lines= eventArgs.UserState.ToString().Split(';');
                string hname = lines[0];
                string cmd = lines[1];
                string val = lines[2];
                OnCommand(this, new CommandEventArgs(hname,cmd,val ));
            }
        }
        private void BackgroundWorker_Completed(object sender, RunWorkerCompletedEventArgs eventArgs)
        {
            this.IsRunning = false;
        }
        #endregion
    }
    //custom event args object
    public delegate void CommandEventHandler(object sender, CommandEventArgs eventArgs);
    public class CommandEventArgs : EventArgs
    {
        public string Command { get; set; }
        public string ComputerName { get; set; }
        public string Value { get; set; }

        public CommandEventArgs(string ComputerName, string Command, string Value )
        {
            this.ComputerName = ComputerName;
            this.Command = Command;
            this.Value = Value;
        }
    }
}
